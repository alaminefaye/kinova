<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Services\LoyaltyService;
use App\Services\NotificationService;
use Illuminate\Http\Request;

class OrderController extends Controller
{
    public function index(Request $request)
    {
        $query = Order::query()->withCount('items')->latest();

        if ($request->filled('status')) {
            $query->where('status', $request->string('status'));
        }

        return response()->json($query->paginate(20));
    }

    public function show(Order $order)
    {
        return response()->json(['data' => $order->load('items')]);
    }

    public function update(Request $request, Order $order, NotificationService $notifications, LoyaltyService $loyalty)
    {
        $data = $request->validate([
            'status' => ['sometimes', 'in:pending,processing,shipped,delivered,cancelled'],
            'notes' => ['nullable', 'string'],
            'tracking_number' => ['nullable', 'string', 'max:120'],
            'carrier' => ['nullable', 'string', 'max:80'],
        ]);

        $previousStatus = $order->status;
        $order->update($data);
        $order = $order->fresh()->load('items');

        if (isset($data['status']) && $data['status'] !== $previousStatus) {
            $notifications->notifyOrderStatus($order);
        } elseif (! empty($data['tracking_number'])) {
            $notifications->notifyOrderStatus($order);
        }

        if ($order->status === 'delivered') {
            $loyalty->awardForDeliveredOrder($order);
        }

        return response()->json(['data' => $order->fresh()->load('items', 'user')]);
    }
}
