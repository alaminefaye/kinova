<?php

namespace App\Http\Controllers\Api\Customer;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Product;
use App\Services\NotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OrderController extends Controller
{
    public function index(Request $request)
    {
        $orders = Order::query()
            ->with('items')
            ->where('user_id', $request->user()->id)
            ->latest()
            ->paginate(50);

        return response()->json($orders);
    }

    public function show(Request $request, string $reference)
    {
        $order = Order::query()
            ->with('items')
            ->where('user_id', $request->user()->id)
            ->where('reference', $reference)
            ->firstOrFail();

        return response()->json(['data' => $order]);
    }

    public function cancel(Request $request, string $reference, NotificationService $notifications)
    {
        $data = $request->validate([
            'reason' => ['nullable', 'string', 'max:500'],
        ]);

        $order = DB::transaction(function () use ($request, $reference, $data) {
            $order = Order::query()
                ->with('items')
                ->where('user_id', $request->user()->id)
                ->where('reference', $reference)
                ->lockForUpdate()
                ->firstOrFail();

            abort_unless(
                $order->can_cancel,
                422,
                $order->payment_status === 'paid'
                    ? 'Cette commande est déjà payée et ne peut plus être annulée. Contactez le service client.'
                    : 'Cette commande ne peut plus être annulée (déjà expédiée, livrée ou annulée). Contactez le service client.'
            );

            $reason = trim((string) ($data['reason'] ?? ''));
            $note = 'Annulée par le client le '.now()->format('d/m/Y H:i').($reason !== '' ? " : {$reason}" : '.');

            $order->update([
                'status' => 'cancelled',
                'notes' => trim(($order->notes ? $order->notes."\n" : '').$note),
            ]);

            foreach ($order->items as $item) {
                if ($item->product_id) {
                    Product::query()->whereKey($item->product_id)->increment('stock', $item->quantity);
                }
            }

            return $order->fresh()->load('items');
        });

        $notifications->notifyOrderStatus($order);
        $notifications->notifyAdminsOrderCancelled($order, $data['reason'] ?? null);

        return response()->json(['data' => $order, 'message' => 'Commande annulée.']);
    }
}
