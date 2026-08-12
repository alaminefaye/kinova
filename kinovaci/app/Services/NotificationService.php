<?php

namespace App\Services;

use App\Models\AppNotification;
use App\Models\Order;
use App\Models\User;
use Illuminate\Support\Collection;

class NotificationService
{
    public function notifyUser(
        User $user,
        string $title,
        string $message,
        string $category = 'system',
        ?string $icon = null,
        ?array $data = null,
    ): AppNotification {
        return AppNotification::query()->create([
            'user_id' => $user->id,
            'title' => $title,
            'message' => $message,
            'category' => $category,
            'icon' => $icon,
            'is_read' => false,
            'data' => $data,
        ]);
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
            'processing' => 'Votre commande est en préparation.',
            'shipped' => 'Votre commande est en route'.($order->tracking_number ? " (suivi: {$order->tracking_number})" : '').'.',
            'delivered' => 'Votre commande a été livrée. Merci !',
            'cancelled' => 'Votre commande a été annulée.',
        ];

        $this->notifyUser(
            $user,
            "Commande {$order->reference}",
            $messages[$order->status] ?? "Statut mis à jour: {$order->status}",
            'order',
            'package',
            [
                'order_reference' => $order->reference,
                'status' => $order->status,
                'tracking_number' => $order->tracking_number,
            ]
        );
    }
}
