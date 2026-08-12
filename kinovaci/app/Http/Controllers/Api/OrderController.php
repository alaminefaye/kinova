<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Product;
use App\Services\NotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class OrderController extends Controller
{
    public function store(Request $request, NotificationService $notifications)
    {
        $data = $request->validate([
            'customer_name' => ['required', 'string', 'max:120'],
            'customer_phone' => ['required', 'string', 'max:40'],
            'customer_email' => ['nullable', 'email'],
            'address' => ['required', 'string', 'max:255'],
            'city' => ['required', 'string', 'max:120'],
            'payment_method' => ['required', 'in:card,cod'],
            'notes' => ['nullable', 'string'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.product_id' => ['required', 'exists:products,id'],
            'items.*.quantity' => ['required', 'integer', 'min:1'],
        ]);

        $userId = $request->user()?->id ?? auth('sanctum')->id();

        $order = DB::transaction(function () use ($data, $userId) {
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

                $lineTotal = $product->price * $item['quantity'];
                $subtotal += $lineTotal;
                $lines[] = compact('product', 'item', 'lineTotal');
            }

            $shipping = $subtotal >= 100 ? 0 : 6.5;
            $total = $subtotal + $shipping;

            $order = Order::query()->create([
                'reference' => 'KV-'.strtoupper(Str::random(8)),
                'user_id' => $userId,
                'customer_name' => $data['customer_name'],
                'customer_phone' => $data['customer_phone'],
                'customer_email' => $data['customer_email'] ?? null,
                'address' => $data['address'],
                'city' => $data['city'],
                'payment_method' => $data['payment_method'],
                'status' => 'pending',
                'subtotal' => $subtotal,
                'shipping' => $shipping,
                'total' => $total,
                'notes' => $data['notes'] ?? null,
            ]);

            foreach ($lines as $line) {
                $order->items()->create([
                    'product_id' => $line['product']->id,
                    'product_name' => $line['product']->name,
                    'unit_price' => $line['product']->price,
                    'quantity' => $line['item']['quantity'],
                    'line_total' => $line['lineTotal'],
                ]);

                $line['product']->decrement('stock', $line['item']['quantity']);
            }

            return $order->load('items');
        });

        if ($order->user_id) {
            $notifications->notifyOrderStatus($order);
        }

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
