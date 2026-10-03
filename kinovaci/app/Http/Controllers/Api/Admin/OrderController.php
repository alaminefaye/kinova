<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Product;
use App\Services\AppSettings;
use App\Services\LoyaltyService;
use App\Services\NotificationService;
use App\Services\StockService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

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

        return response()->json($query->paginate(min(max($request->integer('per_page', 25), 1), 100)));
    }

    public function show(Order $order)
    {
        return response()->json(['data' => $order->load('items')]);
    }

    public function update(Request $request, Order $order, NotificationService $notifications, LoyaltyService $loyalty, StockService $stock)
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

        $order = DB::transaction(function () use ($order, $data, $previousStatus, $stock) {
            $newStatus = $data['status'] ?? $previousStatus;
            $order->loadMissing('items');

            if ($newStatus === 'cancelled' && $previousStatus !== 'cancelled') {
                $stock->restoreOrder($order);
            }

            // Réouverture d'une commande annulée : les articles sont de nouveau réservés.
            if ($previousStatus === 'cancelled' && $newStatus !== 'cancelled') {
                $items = $order->items->filter(fn ($item) => $item->product_id && Product::query()->whereKey($item->product_id)->exists());
                $lines = $items->map(fn ($item) => [
                    'product_id' => $item->product_id,
                    'quantity' => $item->quantity,
                    'selected_size' => $item->selected_size,
                    'selected_color' => $item->selected_color,
                ])->values()->all();
                $products = $stock->reserve($lines, activeOnly: false, requireVariants: false);
                foreach ($items as $item) {
                    $stock->take($products[$item->product_id], (int) $item->quantity, $item->selected_size, $item->selected_color);
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

    /** Commande saisie par un admin (vente en boutique, téléphone…). */
    public function store(Request $request, StockService $stock)
    {
        $isDelivery = $request->boolean('is_delivery', true);

        $data = $request->validate([
            'customer_name' => ['required', 'string', 'max:120'],
            'customer_phone' => ['required', 'string', 'max:40'],
            'customer_email' => ['nullable', 'email', 'max:160'],
            'is_delivery' => ['nullable', 'boolean'],
            'address' => [$isDelivery ? 'required' : 'nullable', 'string', 'max:255'],
            'city' => ['nullable', 'string', 'max:100'],
            'status' => ['nullable', 'in:pending,processing'],
            'notes' => ['nullable', 'string', 'max:5000'],
            'items' => ['required', 'array', 'min:1', 'max:50'],
            'items.*.product_id' => ['required', 'integer', 'exists:products,id'],
            'items.*.quantity' => ['required', 'integer', 'min:1', 'max:999'],
            'items.*.selected_size' => ['nullable', 'string', 'max:50'],
            'items.*.selected_color' => ['nullable', 'string', 'max:50'],
        ]);

        $order = DB::transaction(function () use ($data, $isDelivery, $stock) {
            $subtotal = 0;
            $lines = [];
            $products = $stock->reserve($data['items'], activeOnly: false, requireVariants: false);

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

            $order = Order::query()->create([
                'reference' => 'KV-'.strtoupper(Str::random(8)),
                'customer_name' => $data['customer_name'],
                'customer_phone' => $data['customer_phone'],
                'customer_email' => $data['customer_email'] ?? null,
                'is_delivery' => $isDelivery,
                'address' => $isDelivery ? $data['address'] : 'Retrait en boutique KINOVA',
                'city' => ($data['city'] ?? null) ?: 'Abidjan',
                'payment_method' => 'cod',
                'payment_status' => 'unpaid',
                'status' => $data['status'] ?? 'pending',
                'subtotal' => $subtotal,
                'shipping' => $shipping,
                'total' => $subtotal + $shipping,
                'notes' => ($data['notes'] ?? null) ?: ($isDelivery ? null : 'Retrait en boutique'),
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

            return $order;
        });

        return response()->json(['data' => $order->fresh()->load('items')], 201);
    }
}
