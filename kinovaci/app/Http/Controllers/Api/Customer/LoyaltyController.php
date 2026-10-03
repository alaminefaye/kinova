<?php

namespace App\Http\Controllers\Api\Customer;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\AppSettings;
use App\Services\LoyaltyService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class LoyaltyController extends Controller
{
    public function show(Request $request)
    {
        $user = $request->user();

        $transactions = $user->loyaltyTransactions()
            ->latest()
            ->limit(50)
            ->get();

        return response()->json([
            'data' => [
                'loyalty_points' => $user->loyalty_points,
                'vip_tier' => $user->vip_tier,
                'tiers' => [
                    ['key' => 'standard', 'min' => 0],
                    ['key' => 'silver', 'min' => 500],
                    ['key' => 'gold', 'min' => 1500],
                    ['key' => 'vip', 'min' => 3000],
                ],
                'transactions' => $transactions,
            ],
        ]);
    }

    public function redeem(Request $request, LoyaltyService $loyalty)
    {
        $data = $request->validate([
            'points' => ['required', 'integer', 'min:50'],
        ]);

        abort_unless(AppSettings::loyaltyEnabled(), 422, 'Le programme de fidélité n’est pas disponible.');

        $user = $request->user();

        $tx = DB::transaction(function () use ($user, $data, $loyalty) {
            $locked = User::query()->lockForUpdate()->findOrFail($user->id);
            abort_if($locked->loyalty_points < $data['points'], 422, 'Points insuffisants.');

            return $loyalty->adjust(
                $locked,
                -$data['points'],
                'redeem',
                "Échange de {$data['points']} points"
            );
        });

        return response()->json([
            'message' => 'Points échangés.',
            'data' => [
                'transaction' => $tx,
                'loyalty_points' => $user->fresh()->loyalty_points,
                'vip_tier' => $user->fresh()->vip_tier,
            ],
        ]);
    }
}
