<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Product;
use App\Services\LoyaltyService;
use App\Services\NotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OrderController extends Controller
{
    public function index(Request $request)
    {
        $query = Order::query()
            ->with(['items', 'user:id,name,phone,email,avatar_url'])
            ->withCount('items')
            ->latest();

        if ($request->filled('status')) {
            $query->where('status', $request->string('status'));
        }

        if ($request->filled('q')) {
            $q = $request->string('q');
            $query->where(function ($b) use ($q) {
                $b->where('reference', 'like', "%{$q}%")
                    ->orWhere('customer_name', 'like', "%{$q}%")
                    ->orWhere('customer_phone', 'like', "%{$q}%")
                    ->orWhere('customer_email', 'like', "%{$q}%");
            });
        }

        return response()->json($query->paginate(25));
    }

    public function show(Order $order)
    {
        return response()->json(['data' => $order->load('items')]);
    }

    public function update(Request $request, Order $order, NotificationService $notifications, LoyaltyService $loyalty)
    {
        $data = $request->validate([
            'status' => ['sometimes', 'in:pending,processing,shipped,delivered,cancelled'],
            'notes' => ['nullable', 'string', 'max:5000'],
            'tracking_number' => ['nullable', 'string', 'max:120'],
            'carrier' => ['nullable', 'string', 'max:80'],
            'payment_status' => ['sometimes', 'in:unpaid,paid'],
        ]);

        $previousStatus = $order->status;
        $previousPayment = $order->payment_status;
        $previousTracking = $order->tracking_number;

        // Paiement à la livraison : le colis livré est considéré payé (modifiable ensuite).
        if (($data['status'] ?? null) === 'delivered' && $previousStatus !== 'delivered') {
            $data['delivered_at'] = now();
            if (! array_key_exists('payment_status', $data)) {
                $data['payment_status'] = 'paid';
            }
        }
        if (array_key_exists('payment_status', $data)) {
            $data['paid_at'] = $data['payment_status'] === 'paid' ? ($order->paid_at ?? now()) : null;
        }

        $order = DB::transaction(function () use ($order, $data, $previousStatus) {
            $newStatus = $data['status'] ?? $previousStatus;
            $order->loadMissing('items');

            if ($newStatus === 'cancelled' && $previousStatus !== 'cancelled') {
                foreach ($order->items as $item) {
                    if ($item->product_id) {
                        Product::query()->whereKey($item->product_id)->increment('stock', $item->quantity);
                    }
                }
            }

            // Réouverture d'une commande annulée : les articles sont de nouveau réservés.
            if ($previousStatus === 'cancelled' && $newStatus !== 'cancelled') {
                foreach ($order->items as $item) {
                    if (! $item->product_id) {
                        continue;
                    }
                    $product = Product::query()->whereKey($item->product_id)->lockForUpdate()->first();
                    if ($product && $product->stock < $item->quantity) {
                        abort(422, "Stock insuffisant pour réouvrir la commande ({$product->name}).");
                    }
                    $product?->decrement('stock', $item->quantity);
                }
            }

            $order->update($data);

            return $order->fresh()->load('items');
        });

        $notifications->notifyOrderUpdatedByAdmin(
            $order,
            statusChanged: $order->status !== $previousStatus,
            paymentChanged: $order->payment_status !== $previousPayment,
            trackingChanged: ! empty($order->tracking_number) && $order->tracking_number !== $previousTracking,
        );

        if ($order->status === 'delivered') {
            $loyalty->awardForDeliveredOrder($order);
        }

        return response()->json(['data' => $order->fresh()->load('items', 'user')]);
    }

    public function store(Request $request)
    {
        $isDelivery = $request->boolean('is_delivery', true);

        $data = $request->validate([
            'customer_name' => ['required', 'string', 'max:120'],
            'customer_phone' => ['required', 'string', 'max:40'],
            'customer_email' => ['nullable', 'email', 'max:160'],
            'is_delivery' => ['nullable', 'boolean'],
            'address' => [$isDelivery ? 'required' : 'nullable', 'string', 'max:255'],
            'city' => ['nullable', 'string', 'max:100'],
            'payment_method' => ['nullable', 'string', 'max:50'],
            'status' => ['nullable', 'in:pending,processing,shipped,delivered,cancelled'],
            'notes' => ['nullable', 'string'],
            'tracking_number' => ['nullable', 'string', 'max:120'],
            'carrier' => ['nullable', 'string', 'max:80'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.product_id' => ['required', 'exists:products,id'],
            'items.*.quantity' => ['required', 'integer', 'min:1'],
            'items.*.selected_size' => ['nullable', 'string'],
            'items.*.selected_color' => ['nullable', 'string'],
            'items.*.unit_price' => ['nullable', 'numeric', 'min:0'],
        ]);

        $subtotal = 0;
        $orderItemsData = [];

        foreach ($data['items'] as $it) {
            $product = \App\Models\Product::find($it['product_id']);
            $unitPrice = isset($it['unit_price']) ? (float) $it['unit_price'] : (float) ($product->promo_price ?? $product->price);
            $qty = (int) $it['quantity'];
            $lineTotal = $unitPrice * $qty;
            $subtotal += $lineTotal;

            if ($product) {
                if ($product->stock >= $qty) {
                    $product->decrement('stock', $qty);
                } else {
                    $product->update(['stock' => 0]);
                }
            }

            $orderItemsData[] = [
                'product_id' => $product->id,
                'product_name' => $product->name,
                'unit_price' => $unitPrice,
                'quantity' => $qty,
                'selected_size' => $it['selected_size'] ?? null,
                'selected_color' => $it['selected_color'] ?? null,
                'line_total' => $lineTotal,
            ];
        }

        $shipping = \App\Services\AppSettings::shippingFor($subtotal, $isDelivery);
        $total = $subtotal + $shipping;

        $reference = 'CMD-'.strtoupper(\Illuminate\Support\Str::random(6));

        $order = Order::create([
            'reference' => $reference,
            'customer_name' => $data['customer_name'],
            'customer_phone' => $data['customer_phone'],
            'customer_email' => $data['customer_email'] ?? null,
            'is_delivery' => $isDelivery,
            'address' => $isDelivery ? $data['address'] : ($data['address'] ?? 'Retrait en boutique KINOVA'),
            'city' => $isDelivery ? ($data['city'] ?? 'Abidjan') : ($data['city'] ?? 'Abidjan'),
            'payment_method' => $data['payment_method'] ?? 'cash_on_delivery',
            'status' => $data['status'] ?? 'pending',
            'subtotal' => $subtotal,
            'shipping' => $shipping,
            'total' => $total,
            'notes' => $data['notes'] ?? ($isDelivery ? null : 'Retrait en boutique'),
            'tracking_number' => $data['tracking_number'] ?? null,
            'carrier' => $data['carrier'] ?? null,
        ]);

        foreach ($orderItemsData as $itemData) {
            $order->items()->create($itemData);
        }

        return response()->json(['data' => $order->fresh()->load('items', 'user')], 201);
    }
}
