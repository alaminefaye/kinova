<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Order;
use App\Models\Product;

class DashboardController extends Controller
{
    public function __invoke()
    {
        return response()->json([
            'data' => [
                'products_count' => Product::query()->count(),
                'categories_count' => Category::query()->count(),
                'orders_count' => Order::query()->count(),
                'pending_orders' => Order::query()->where('status', 'pending')->count(),
                'revenue' => (float) Order::query()->whereNotIn('status', ['cancelled'])->sum('total'),
                'latest_orders' => Order::query()->latest()->limit(5)->get(),
                'low_stock' => Product::query()->where('stock', '<=', 5)->orderBy('stock')->limit(5)->get(['id', 'name', 'stock']),
            ],
        ]);
    }
}
