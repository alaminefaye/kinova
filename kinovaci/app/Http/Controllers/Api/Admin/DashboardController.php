<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Order;
use App\Models\Product;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Eloquent\Builder;

class DashboardController extends Controller
{
    /** Une vente est datée du jour de l'encaissement. */
    private const SALE_DATE = 'DATE(COALESCE(paid_at, created_at))';

    /** Seules les commandes payées (non annulées) comptent dans le chiffre d'affaires. */
    private function sales(): Builder
    {
        return Order::query()
            ->where('payment_status', 'paid')
            ->where('status', '!=', 'cancelled');
    }

    public function __invoke()
    {
        $today = Carbon::today();
        $startOfMonth = Carbon::now()->startOfMonth();

        $todayRevenue = (float) $this->sales()->whereRaw(self::SALE_DATE.' = ?', [$today->toDateString()])->sum('total');
        $todaySalesCount = $this->sales()->whereRaw(self::SALE_DATE.' = ?', [$today->toDateString()])->count();

        $todayOrdersCount = Order::query()
            ->whereDate('created_at', $today)
            ->count();

        $monthRevenue = (float) $this->sales()->whereRaw(self::SALE_DATE.' >= ?', [$startOfMonth->toDateString()])->sum('total');
        $monthSalesCount = $this->sales()->whereRaw(self::SALE_DATE.' >= ?', [$startOfMonth->toDateString()])->count();

        $monthOrdersCount = Order::query()
            ->where('created_at', '>=', $startOfMonth)
            ->count();

        $totalRevenue = (float) $this->sales()->sum('total');
        $totalSalesCount = $this->sales()->count();

        $totalOrdersCount = Order::query()->count();

        $pendingOrders = Order::query()->where('status', 'pending')->count();
        $processingOrders = Order::query()->whereIn('status', ['processing', 'shipped'])->count();
        $deliveredOrders = Order::query()->where('status', 'delivered')->count();
        $cancelledOrders = Order::query()->where('status', 'cancelled')->count();

        $totalCustomers = User::query()
            ->where(function ($q) {
                $q->where('role', 'customer')
                    ->orWhereDoesntHave('roles', function ($r) {
                        $r->whereIn('name', ['admin', 'super-admin', 'manager']);
                    });
            })
            ->count();

        $newCustomersToday = User::query()
            ->whereDate('created_at', $today)
            ->count();

        $productsCount = Product::query()->count();
        $categoriesCount = Category::query()->count();

        // 7 Derniers Jours pour Graphique Ventes
        $salesByDay = [];
        $dayNames = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];

        for ($i = 6; $i >= 0; $i--) {
            $date = Carbon::today()->subDays($i);
            $dayOfWeek = $dayNames[$date->dayOfWeek];
            $isToday = $i === 0;

            $amount = (float) $this->sales()->whereRaw(self::SALE_DATE.' = ?', [$date->toDateString()])->sum('total');
            $count = $this->sales()->whereRaw(self::SALE_DATE.' = ?', [$date->toDateString()])->count();

            $salesByDay[] = [
                'date' => $date->format('Y-m-d'),
                'label' => $isToday ? 'Auj.' : $dayOfWeek,
                'amount' => $amount,
                'count' => $count,
            ];
        }

        // Produits en stock critique ou rupture
        $lowStock = Product::query()
            ->where('stock', '<=', 5)
            ->orderBy('stock')
            ->limit(8)
            ->get(['id', 'name', 'stock', 'price', 'promo_price', 'image_url']);

        // Dernières commandes
        $latestOrders = Order::query()
            ->with(['items', 'user:id,name,email,phone,avatar_url'])
            ->latest()
            ->limit(8)
            ->get();

        return response()->json([
            'data' => [
                'today_revenue' => $todayRevenue,
                'today_sales_count' => $todaySalesCount,
                'today_orders_count' => $todayOrdersCount,
                'month_revenue' => $monthRevenue,
                'month_sales_count' => $monthSalesCount,
                'month_orders_count' => $monthOrdersCount,
                'total_revenue' => $totalRevenue,
                'total_sales_count' => $totalSalesCount,
                'revenue' => $totalRevenue,
                'orders_count' => $totalOrdersCount,
                'pending_orders' => $pendingOrders,
                'processing_orders' => $processingOrders,
                'delivered_orders' => $deliveredOrders,
                'cancelled_orders' => $cancelledOrders,
                'total_customers' => $totalCustomers,
                'new_customers_today' => $newCustomersToday,
                'products_count' => $productsCount,
                'categories_count' => $categoriesCount,
                'sales_by_day' => $salesByDay,
                'low_stock' => $lowStock,
                'latest_orders' => $latestOrders,
            ],
        ]);
    }
}
