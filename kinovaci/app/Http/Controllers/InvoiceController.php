<?php

namespace App\Http\Controllers;

use App\Models\Order;
use Illuminate\Http\Request;

class InvoiceController extends Controller
{
    public function show(Request $request, string $reference)
    {
        $order = Order::query()
            ->with('items')
            ->where('reference', $reference)
            ->firstOrFail();

        abort_unless(hash_equals($order->invoiceToken(), (string) $request->query('t')), 404);

        return view('invoice', [
            'order' => $order,
            'support' => [
                'email' => config('kinova.support_email'),
                'phone' => config('kinova.support_phone'),
            ],
        ]);
    }
}
