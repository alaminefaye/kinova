<?php

namespace App\Http\Controllers\Api\Customer;

use App\Http\Controllers\Controller;
use App\Services\LoyaltyService;
use Illuminate\Http\Request;

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

        $user = $request->user();

        if ($user->loyalty_points < $data['points']) {
            return response()->json(['message' => 'Points insuffisants.'], 422);
        }

        $tx = $loyalty->adjust(
            $user,
            -$data['points'],
            'redeem',
            "Échange de {$data['points']} points"
        );

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
