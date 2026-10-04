<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Services\AppSettings;
use App\Services\NotificationService;
use App\Services\StockService;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class OrderController extends Controller
{
    public function store(Request $request, NotificationService $notifications, StockService $stock)
    {
        $isDelivery = $request->boolean('is_delivery', true);
        $hasPosition = $request->filled('latitude') && $request->filled('longitude');

        $data = $request->validate([
            'customer_name' => ['required', 'string', 'max:120'],
            'customer_phone' => ['required', 'string', 'max:40'],
            'customer_email' => ['nullable', 'email'],
            'is_delivery' => ['nullable', 'boolean'],
            'address' => [($isDelivery && ! $hasPosition) ? 'required' : 'nullable', 'string', 'max:255'],
            'city' => ['nullable', 'string', 'max:120'],
            'latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['nullable', 'numeric', 'between:-180,180'],
            'delivery_details' => ['nullable', 'string', 'max:1000'],
            'payment_method' => ['nullable', 'string', 'max:50'],
            'notes' => ['nullable', 'string', 'max:2000'],
            'client_token' => ['nullable', 'string', 'alpha_dash', 'min:16', 'max:64'],
            'items' => ['required', 'array', 'min:1', 'max:50'],
            'items.*.product_id' => ['required', 'integer', 'exists:products,id'],
            'items.*.quantity' => ['required', 'integer', 'min:1', 'max:20'],
            'items.*.selected_size' => ['nullable', 'string', 'max:50'],
            'items.*.selected_color' => ['nullable', 'string', 'max:50'],
        ], [
            'items.*.quantity.max' => 'Maximum 20 exemplaires par article.',
        ]);

        $userId = $request->user()?->id ?? auth('sanctum')->id();
        $clientToken = $data['client_token'] ?? null;

        // Nouvel envoi de la même commande (réseau coupé avant la réponse) : on renvoie l'existante.
        if ($existing = $this->findRetriedOrder($clientToken, $userId)) {
            return response()->json(['data' => $existing], 200);
        }

        // Le stock est réservé dès la commande : on empêche de bloquer le catalogue avec de fausses commandes.
        abort_if(
            collect($data['items'])->sum('quantity') > 50,
            422,
            'Commande limitée à 50 articles. Contactez-nous pour une commande plus importante.'
        );
        abort_if(
            Order::query()
                ->where('customer_phone', $data['customer_phone'])
                ->where('status', 'pending')
                ->count() >= 3,
            429,
            'Vous avez déjà 3 commandes en attente. Notre équipe vous contacte rapidement ; vous pouvez aussi nous appeler.'
        );

        try {
            $order = $this->createOrder($data, $userId, $isDelivery, $clientToken, $stock);
        } catch (UniqueConstraintViolationException $e) {
            $existing = $this->findRetriedOrder($clientToken, $userId);
            abort_unless($existing, 409, 'Commande déjà envoyée.');

            return response()->json(['data' => $existing], 200);
        }

        // Notifications et push envoyés après la réponse : le client n'attend pas Firebase.
        // Les callbacks terminating restent enregistrés si l'application est réutilisée (tests, Octane).
        $sent = false;
        app()->terminating(function () use ($notifications, $order, &$sent) {
            if ($sent) {
                return;
            }
            $sent = true;
            $notifications->notifyOrderCreated($order);
            $notifications->notifyAdminsNewOrder($order);
        });

        return response()->json(['data' => $order], 201);
    }

    private function findRetriedOrder(?string $clientToken, ?int $userId): ?Order
    {
        if (! $clientToken) {
            return null;
        }
        $order = Order::query()->with('items')->where('client_token', $clientToken)->first();
        if (! $order) {
            return null;
        }
        abort_unless((string) $order->user_id === (string) $userId, 409, 'Commande déjà envoyée.');

        return $order;
    }

    private function createOrder(array $data, ?int $userId, bool $isDelivery, ?string $clientToken, StockService $stock): Order
    {
        return DB::transaction(function () use ($data, $userId, $isDelivery, $clientToken, $stock) {
            $subtotal = 0;
            $lines = [];
            $products = $stock->reserve($data['items']);

            foreach ($data['items'] as $item) {
                $product = $products[$item['product_id']];

                $unitPrice = ($product->promo_price !== null && $product->promo_price > 0 && $product->promo_price < $product->price)
                    ? (float) $product->promo_price
                    : (float) $product->price;

                $lineTotal = $unitPrice * $item['quantity'];
                $subtotal += $lineTotal;
                $lines[] = compact('product', 'item', 'unitPrice', 'lineTotal');
            }

            $shipping = AppSettings::shippingFor($subtotal, $isDelivery);
            $total = $subtotal + $shipping;

            $order = Order::query()->create([
                'reference' => 'KV-'.strtoupper(Str::random(8)),
                'client_token' => $clientToken,
                'user_id' => $userId,
                'customer_name' => $data['customer_name'],
                'customer_phone' => $data['customer_phone'],
                'customer_email' => $data['customer_email'] ?? null,
                'is_delivery' => $isDelivery,
                'address' => $isDelivery
                    ? (($data['address'] ?? null) ?: 'Position GPS partagée')
                    : 'Retrait en boutique KINOVA',
                'city' => ($data['city'] ?? null) ?: 'Abidjan',
                'latitude' => $isDelivery ? ($data['latitude'] ?? null) : null,
                'longitude' => $isDelivery ? ($data['longitude'] ?? null) : null,
                'delivery_details' => $isDelivery ? ($data['delivery_details'] ?? null) : null,
                // Seul mode de paiement proposé : à la livraison / au retrait
                'payment_method' => 'cod',
                'payment_status' => 'unpaid',
                'status' => 'pending',
                'subtotal' => $subtotal,
                'shipping' => $shipping,
                'total' => $total,
                'notes' => $data['notes'] ?? ($isDelivery ? null : 'Retrait en boutique'),
            ]);

            foreach ($lines as $line) {
                $order->items()->create([
                    'product_id' => $line['product']->id,
                    'product_name' => $line['product']->name,
                    'selected_size' => $line['item']['selected_size'] ?? null,
                    'selected_color' => $line['item']['selected_color'] ?? null,
                    'unit_price' => $line['unitPrice'],
                    'quantity' => $line['item']['quantity'],
                    'line_total' => $line['lineTotal'],
                ]);

                $stock->take(
                    $line['product'],
                    (int) $line['item']['quantity'],
                    $line['item']['selected_size'] ?? null,
                    $line['item']['selected_color'] ?? null,
                );
            }

            return $order->load('items');
        });
    }

    public function show(string $reference)
    {
        $order = Order::query()
            ->with('items')
            ->where('reference', $reference)
            ->firstOrFail();

        // Suivi public par référence : aucune donnée personnelle (téléphone, adresse, GPS, notes).
        return response()->json(['data' => [
            'reference' => $order->reference,
            'status' => $order->status,
            'payment_status' => $order->payment_status,
            'subtotal' => $order->subtotal,
            'shipping' => $order->shipping,
            'total' => $order->total,
            'is_delivery' => $order->is_delivery,
            'tracking_number' => $order->tracking_number,
            'carrier' => $order->carrier,
            'created_at' => $order->created_at,
            'items' => $order->items->map->only([
                'product_id', 'product_name', 'selected_size', 'selected_color', 'unit_price', 'quantity', 'line_total',
            ])->values(),
        ]]);
    }
}
