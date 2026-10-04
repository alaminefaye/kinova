<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Order;
use App\Models\Product;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Query\Builder as QueryBuilder;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    /** Une vente est datée du jour de l'encaissement. */
    private const SALE_DATE = 'DATE(COALESCE(paid_at, created_at))';

    /** Au-delà, la courbe « depuis le lancement » est regroupée par mois uniquement. */
    private const MAX_HISTORY_DAYS = 730;

    private const DAY_NAMES = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];

    private const MONTH_NAMES = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];

    /** Seules les commandes payées (non annulées) comptent dans le chiffre d'affaires. */
    private function sales(): Builder
    {
        return Order::query()
            ->where('payment_status', 'paid')
            ->where('status', '!=', 'cancelled');
    }

    /** Lignes vendues (commandes payées, non annulées). */
    private function soldItems(): QueryBuilder
    {
        return DB::table('order_items')
            ->join('orders', 'orders.id', '=', 'order_items.order_id')
            ->where('orders.payment_status', 'paid')
            ->where('orders.status', '!=', 'cancelled');
    }

    public function __invoke()
    {
        $today = Carbon::today();
        $yesterday = $today->copy()->subDay();
        $startOfMonth = $today->copy()->startOfMonth();
        $startOfLastMonth = $startOfMonth->copy()->subMonth();

        // Recettes par jour (une seule requête), base de tous les montants et graphiques.
        $daily = $this->sales()
            ->toBase()
            ->selectRaw(self::SALE_DATE.' as day, SUM(total) as amount, COUNT(*) as sales')
            ->groupByRaw(self::SALE_DATE)
            ->orderBy('day')
            ->get()
            ->mapWithKeys(fn ($row) => [substr((string) $row->day, 0, 10) => [
                'amount' => (float) $row->amount,
                'count' => (int) $row->sales,
            ]]);

        $between = function (Carbon $from, Carbon $to) use ($daily): array {
            $rows = $daily->filter(fn ($v, $day) => $day >= $from->toDateString() && $day <= $to->toDateString());

            return [(float) $rows->sum('amount'), (int) $rows->sum('count')];
        };

        [$todayRevenue, $todaySalesCount] = $between($today, $today);
        [$yesterdayRevenue, $yesterdaySalesCount] = $between($yesterday, $yesterday);
        [$monthRevenue, $monthSalesCount] = $between($startOfMonth, $today);
        [$lastMonthRevenue] = $between($startOfLastMonth, $startOfMonth->copy()->subDay());
        $totalRevenue = (float) $daily->sum('amount');
        $totalSalesCount = (int) $daily->sum('count');

        $firstSaleDate = $daily->keys()->first();

        $todayOrdersCount = Order::query()->whereDate('created_at', $today)->count();
        $monthOrdersCount = Order::query()->where('created_at', '>=', $startOfMonth)->count();
        $totalOrdersCount = Order::query()->count();

        $statusCounts = Order::query()
            ->toBase()
            ->selectRaw('status, COUNT(*) as total')
            ->groupBy('status')
            ->pluck('total', 'status')
            ->map(fn ($v) => (int) $v);

        $pendingOrders = $statusCounts['pending'] ?? 0;
        $processingOrders = ($statusCounts['processing'] ?? 0) + ($statusCounts['shipped'] ?? 0);
        $deliveredOrders = $statusCounts['delivered'] ?? 0;
        $cancelledOrders = $statusCounts['cancelled'] ?? 0;

        $totalCustomers = User::query()
            ->where(function ($q) {
                $q->where('role', 'customer')
                    ->orWhereDoesntHave('roles', function ($r) {
                        $r->whereIn('name', ['admin', 'super-admin', 'manager']);
                    });
            })
            ->count();

        $newCustomersToday = User::query()->whereDate('created_at', $today)->count();

        $topProducts = $this->soldItems()
            ->selectRaw('order_items.product_name as name, SUM(order_items.quantity) as quantity, SUM(order_items.line_total) as revenue')
            ->groupBy('order_items.product_name')
            ->orderByDesc('quantity')
            ->orderByDesc('revenue')
            ->limit(5)
            ->get()
            ->map(fn ($row) => [
                'name' => $row->name,
                'quantity' => (int) $row->quantity,
                'revenue' => (float) $row->revenue,
            ]);

        $categoryName = "COALESCE(categories.name, 'Autres')";
        $revenueByCategory = $this->soldItems()
            ->leftJoin('products', 'products.id', '=', 'order_items.product_id')
            ->leftJoin('categories', 'categories.id', '=', 'products.category_id')
            ->selectRaw("{$categoryName} as name, SUM(order_items.line_total) as revenue")
            ->groupByRaw($categoryName)
            ->orderByDesc('revenue')
            ->get()
            ->map(fn ($row) => ['name' => $row->name, 'revenue' => (float) $row->revenue]);

        $lowStock = Product::query()
            ->where('stock', '<=', 5)
            ->orderBy('stock')
            ->limit(8)
            ->get(['id', 'name', 'stock', 'price', 'promo_price', 'image_url']);

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
                'yesterday_revenue' => $yesterdayRevenue,
                'yesterday_sales_count' => $yesterdaySalesCount,
                'month_revenue' => $monthRevenue,
                'month_sales_count' => $monthSalesCount,
                'month_orders_count' => $monthOrdersCount,
                'last_month_revenue' => $lastMonthRevenue,
                'total_revenue' => $totalRevenue,
                'total_sales_count' => $totalSalesCount,
                'average_basket' => $totalSalesCount > 0 ? round($totalRevenue / $totalSalesCount) : 0,
                'first_sale_date' => $firstSaleDate,
                'revenue' => $totalRevenue,
                'orders_count' => $totalOrdersCount,
                'pending_orders' => $pendingOrders,
                'processing_orders' => $processingOrders,
                'delivered_orders' => $deliveredOrders,
                'cancelled_orders' => $cancelledOrders,
                'orders_by_status' => [
                    'pending' => $pendingOrders,
                    'processing' => $statusCounts['processing'] ?? 0,
                    'shipped' => $statusCounts['shipped'] ?? 0,
                    'delivered' => $deliveredOrders,
                    'cancelled' => $cancelledOrders,
                ],
                'total_customers' => $totalCustomers,
                'new_customers_today' => $newCustomersToday,
                'products_count' => Product::query()->count(),
                'categories_count' => Category::query()->count(),
                'sales_by_day' => $this->dailySeries($daily, $today->copy()->subDays(6), $today, shortLabels: true),
                'sales_last_30_days' => $this->dailySeries($daily, $today->copy()->subDays(29), $today),
                'sales_since_start' => $this->sinceStartSeries($daily, $firstSaleDate, $today),
                'sales_by_month' => $this->monthlySeries($daily, $firstSaleDate, $today),
                'top_products' => $topProducts,
                'revenue_by_category' => $revenueByCategory,
                'low_stock' => $lowStock,
                'latest_orders' => $latestOrders,
            ],
        ]);
    }

    /** Un point par jour (jours sans vente à 0). */
    private function dailySeries(Collection $daily, Carbon $from, Carbon $to, bool $shortLabels = false): array
    {
        $series = [];
        for ($date = $from->copy(); $date->lte($to); $date->addDay()) {
            $key = $date->toDateString();
            $series[] = [
                'date' => $key,
                'label' => $shortLabels
                    ? ($date->isSameDay($to) ? 'Auj.' : self::DAY_NAMES[$date->dayOfWeek])
                    : $date->day.' '.self::MONTH_NAMES[$date->month - 1],
                'amount' => $daily[$key]['amount'] ?? 0.0,
                'count' => $daily[$key]['count'] ?? 0,
            ];
        }

        return $series;
    }

    /** Cumul jour par jour depuis la première vente (limité aux deux dernières années). */
    private function sinceStartSeries(Collection $daily, ?string $firstSaleDate, Carbon $today): array
    {
        if (! $firstSaleDate) {
            return [];
        }

        $from = Carbon::parse($firstSaleDate)->max($today->copy()->subDays(self::MAX_HISTORY_DAYS));
        $cumulative = (float) $daily->filter(fn ($v, $day) => $day < $from->toDateString())->sum('amount');

        return collect($this->dailySeries($daily, $from, $today))
            ->map(function ($point) use (&$cumulative) {
                $cumulative += $point['amount'];

                return ['date' => $point['date'], 'label' => $point['label'], 'total' => $cumulative];
            })
            ->all();
    }

    /** Recettes par mois depuis le lancement (au moins les 6 derniers mois pour un graphique lisible). */
    private function monthlySeries(Collection $daily, ?string $firstSaleDate, Carbon $today): array
    {
        $start = $today->copy()->startOfMonth()->subMonths(5);
        if ($firstSaleDate && Carbon::parse($firstSaleDate)->startOfMonth()->lt($start)) {
            $start = Carbon::parse($firstSaleDate)->startOfMonth()->max($today->copy()->startOfMonth()->subMonths(23));
        }

        $series = [];
        for ($month = $start->copy(); $month->lte($today); $month->addMonth()) {
            $prefix = $month->format('Y-m');
            $rows = $daily->filter(fn ($v, $day) => str_starts_with($day, $prefix));
            $series[] = [
                'month' => $prefix,
                'label' => self::MONTH_NAMES[$month->month - 1].' '.$month->format('y'),
                'amount' => (float) $rows->sum('amount'),
                'count' => (int) $rows->sum('count'),
            ];
        }

        return $series;
    }
}
