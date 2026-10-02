<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Product;
use App\Services\AppSettings;
use App\Services\NotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class OrderController extends Controller
{
    public function store(Request $request, NotificationService $notifications)
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
            'notes' => ['nullable', 'string'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.product_id' => ['required', 'exists:products,id'],
            'items.*.quantity' => ['required', 'integer', 'min:1'],
            'items.*.selected_size' => ['nullable', 'string', 'max:50'],
            'items.*.selected_color' => ['nullable', 'string', 'max:50'],
        ]);

        $userId = $request->user()?->id ?? auth('sanctum')->id();

        $order = DB::transaction(function () use ($data, $userId, $isDelivery) {
            $subtotal = 0;
            $lines = [];

            foreach ($data['items'] as $item) {
                $product = Product::query()
                    ->where('id', $item['product_id'])
                    ->where('is_active', true)
                    ->lockForUpdate()
                    ->firstOrFail();

                if ($product->stock < $item['quantity']) {
                    abort(422, "Stock insuffisant pour {$product->name}");
                }

                // Vérifier le stock de la taille si spécifiée
                if (!empty($item['selected_size']) && is_array($product->sizes)) {
                    $sizeOption = collect($product->sizes)->firstWhere('name', $item['selected_size']);
                    if ($sizeOption && isset($sizeOption['stock']) && $sizeOption['stock'] < $item['quantity']) {
                        abort(422, "Taille {$item['selected_size']} épuisée pour {$product->name}");
                    }
                }

                // Vérifier le stock de la couleur si spécifiée
                if (!empty($item['selected_color']) && is_array($product->colors)) {
                    $colorOption = collect($product->colors)->firstWhere('name', $item['selected_color']);
                    if ($colorOption && isset($colorOption['stock']) && $colorOption['stock'] < $item['quantity']) {
                        abort(422, "Couleur {$item['selected_color']} épuisée pour {$product->name}");
                    }
                }

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

                $line['product']->decrement('stock', $line['item']['quantity']);
            }

            return $order->load('items');
        });

        $notifications->notifyOrderCreated($order);
        $notifications->notifyAdminsNewOrder($order);

        return response()->json(['data' => $order], 201);
    }

    public function show(string $reference)
    {
        $order = Order::query()
            ->with('items')
            ->where('reference', $reference)
            ->firstOrFail();

        return response()->json(['data' => $order]);
    }
}
