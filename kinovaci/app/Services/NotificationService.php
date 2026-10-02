<?php

namespace App\Services;

use App\Models\AppNotification;
use App\Models\Order;
use App\Models\User;
use Illuminate\Support\Collection;

class NotificationService
{
    public function __construct(
        private readonly FirebasePushService $push,
    ) {}

    public function notifyUser(
        User $user,
        string $title,
        string $message,
        string $category = 'system',
        ?string $icon = null,
        ?array $data = null,
    ): AppNotification {
        $notification = AppNotification::query()->create([
            'user_id' => $user->id,
            'title' => $title,
            'message' => $message,
            'category' => $category,
            'icon' => $icon,
            'is_read' => false,
            'data' => $data,
        ]);

        $this->push->sendToUser($user, $title, $message, $category, $data);

        return $notification;
    }

    public function broadcast(
        string $title,
        string $message,
        string $category = 'promo',
        ?string $icon = null,
        ?array $data = null,
        ?array $userIds = null,
    ): Collection {
        $query = User::query()->where('role', 'customer');
        if ($userIds) {
            $query->whereIn('id', $userIds);
        }

        $users = $query->get();
        $created = collect();

        foreach ($users as $user) {
            $created->push($this->notifyUser($user, $title, $message, $category, $icon, $data));
        }

        if (! $userIds) {
            // Also keep a broadcast copy without user for admin history
            $created->push(AppNotification::query()->create([
                'user_id' => null,
                'title' => $title,
                'message' => $message,
                'category' => $category,
                'icon' => $icon,
                'is_read' => true,
                'data' => $data,
            ]));
        }

        return $created;
    }

    public function notifyOrderCreated(Order $order): void
    {
        $user = $order->user_id ? ($order->user ?? User::query()->find($order->user_id)) : null;
        if (! $user) {
            return;
        }

        $order->loadMissing('items');
        $total = AppSettings::formatMoney((float) $order->total);
        $delivery = $order->is_delivery
            ? 'Livraison à domicile (frais à régler au livreur).'
            : 'Retrait en boutique.';
        if ($order->is_delivery && (float) $order->shipping > 0) {
            $delivery = 'Livraison : '.AppSettings::formatMoney((float) $order->shipping).'.';
        }

        $this->notifyUser(
            $user,
            "Commande {$order->reference} enregistrée",
            "Vous avez commandé : {$this->itemsSummary($order)}. Total : {$total}. {$delivery} "
                .'Paiement à la livraison. Votre facture provisoire est disponible, nous vous appelons pour confirmer.',
            'order',
            'package',
            [
                'type' => 'order_created',
                'order_reference' => $order->reference,
                'status' => $order->status,
                'invoice_status' => $order->invoice_status,
            ]
        );
    }

    public function notifyAdminsNewOrder(Order $order): void
    {
        $order->loadMissing('items');
        $total = AppSettings::formatMoney((float) $order->total);
        $mode = $order->is_delivery ? 'Livraison' : 'Retrait boutique';

        foreach ($this->admins() as $admin) {
            $this->notifyUser(
                $admin,
                'Nouvelle commande reçue',
                "{$order->customer_name} ({$order->customer_phone}) — {$this->itemsSummary($order)}. "
                    ."Total : {$total}. {$mode}. Appelez le client pour confirmer.",
                'order',
                'package',
                [
                    'type' => 'admin_new_order',
                    'order_reference' => $order->reference,
                    'order_id' => $order->id,
                    'customer_phone' => $order->customer_phone,
                ]
            );
        }
    }

    public function notifyAdminsOrderCancelled(Order $order, ?string $reason = null): void
    {
        $order->loadMissing('items');
        $total = AppSettings::formatMoney((float) $order->total);
        $reason = trim((string) $reason);

        foreach ($this->admins() as $admin) {
            $this->notifyUser(
                $admin,
                "Commande {$order->reference} annulée",
                "{$order->customer_name} ({$order->customer_phone}) a annulé sa commande : {$this->itemsSummary($order)}. "
                    ."Total : {$total}.".($reason !== '' ? " Motif : {$reason}" : ''),
                'order',
                'package',
                [
                    'type' => 'admin_order_cancelled',
                    'order_reference' => $order->reference,
                    'order_id' => $order->id,
                    'customer_phone' => $order->customer_phone,
                ]
            );
        }
    }

    /**
     * @return Collection<int, User>
     */
    private function admins(): Collection
    {
        return User::query()
            ->where('is_blocked', false)
            ->whereHas('roles', fn ($q) => $q->where('name', 'super-admin'))
            ->get()
            ->unique('id')
            ->values();
    }

    private function itemsSummary(Order $order): string
    {
        $lines = $order->items->map(fn ($item) => "{$item->product_name} ×{$item->quantity}");
        $summary = $lines->take(3)->implode(', ');
        if ($lines->count() > 3) {
            $summary .= ' +'.($lines->count() - 3).' autre(s)';
        }

        return $summary;
    }

    public const STATUS_LABELS = [
        'pending' => 'En attente',
        'processing' => 'Confirmée',
        'shipped' => 'Expédiée',
        'delivered' => 'Livrée',
        'cancelled' => 'Annulée',
    ];

    /**
     * Notifie le client d'une modification faite par l'admin, en décrivant ce qui a changé.
     * Un seul push même si plusieurs champs changent en même temps.
     */
    public function notifyOrderUpdatedByAdmin(
        Order $order,
        bool $statusChanged,
        bool $paymentChanged,
        bool $trackingChanged,
    ): void {
        $user = $order->user_id ? ($order->user ?? User::query()->find($order->user_id)) : null;
        if (! $user || (! $statusChanged && ! $paymentChanged && ! $trackingChanged)) {
            return;
        }

        $ref = $order->reference;
        $total = AppSettings::formatMoney((float) $order->total);
        $tracking = $order->tracking_number
            ? " Suivi : {$order->tracking_number}".($order->carrier ? " ({$order->carrier})" : '').'.'
            : '';
        $parts = [];

        if ($statusChanged) {
            $title = "Commande {$ref} : ".(self::STATUS_LABELS[$order->status] ?? $order->status);
            $parts[] = match ($order->status) {
                'pending' => 'Votre commande est repassée en attente. Nous vous recontacterons.',
                'processing' => 'Bonne nouvelle ! Votre commande est confirmée et en cours de préparation.',
                'shipped' => $order->is_delivery
                    ? 'Votre commande est en route. Le livreur vous appellera. Paiement à la réception, frais de livraison à régler au livreur.'
                    : 'Votre commande est prête : vous pouvez venir la retirer en boutique. Paiement au retrait.',
                'delivered' => $order->payment_status === 'paid'
                    ? "Commande livrée et payée ({$total}). Votre facture est désormais définitive. Merci pour votre confiance !"
                    : 'Votre commande a été livrée. Merci pour votre confiance !',
                'cancelled' => 'Votre commande a été annulée par la boutique. Pour toute question, contactez notre service client.',
                default => 'Le statut de votre commande a été mis à jour.',
            };
            if ($order->status === 'shipped' || $trackingChanged) {
                $parts[] = trim($tracking);
            }
        } elseif ($paymentChanged) {
            $title = $order->payment_status === 'paid' ? "Paiement reçu — {$ref}" : "Paiement — {$ref}";
            $parts[] = $order->payment_status === 'paid'
                ? "Nous avons bien reçu votre paiement de {$total}."
                    .($order->invoice_status === 'confirmed' ? ' Votre facture est désormais définitive.' : '')
                : 'Le paiement de votre commande est indiqué comme non reçu. Contactez-nous en cas d’erreur.';
            if ($trackingChanged) {
                $parts[] = trim($tracking);
            }
        } else {
            $title = "Commande {$ref} : suivi de livraison";
            $parts[] = 'Votre numéro de suivi est disponible.'.$tracking;
        }

        $this->notifyUser(
            $user,
            $title,
            implode(' ', array_filter($parts)),
            'order',
            'package',
            [
                'type' => 'order_status',
                'order_reference' => $ref,
                'status' => $order->status,
                'payment_status' => $order->payment_status,
                'tracking_number' => $order->tracking_number,
                'invoice_status' => $order->invoice_status,
            ]
        );
    }

    public function notifyOrderStatus(Order $order): void
    {
        if (! $order->user_id) {
            return;
        }

        $user = $order->user ?? User::query()->find($order->user_id);
        if (! $user) {
            return;
        }

        $messages = [
            'pending' => 'Votre commande a été reçue.',
            'processing' => 'Votre commande est confirmée et en préparation.',
            'shipped' => 'Votre commande est en route'.($order->tracking_number ? " (suivi: {$order->tracking_number})" : '').'.',
            'delivered' => $order->payment_status === 'paid'
                ? 'Votre commande a été livrée et payée. Votre facture est désormais définitive. Merci !'
                : 'Votre commande a été livrée. Merci !',
            'cancelled' => 'Votre commande a été annulée.',
        ];

        $this->notifyUser(
            $user,
            "Commande {$order->reference}",
            $messages[$order->status] ?? "Statut mis à jour: {$order->status}",
            'order',
            'package',
            [
                'type' => 'order_status',
                'order_reference' => $order->reference,
                'status' => $order->status,
                'tracking_number' => $order->tracking_number,
                'invoice_status' => $order->invoice_status,
            ]
        );
    }
}
