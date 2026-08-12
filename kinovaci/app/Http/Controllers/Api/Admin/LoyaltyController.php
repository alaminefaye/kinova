<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\LoyaltyService;
use Illuminate\Http\Request;

class LoyaltyController extends Controller
{
    public function customers(Request $request)
    {
        $query = User::query()
            ->where('role', 'customer')
            ->orderByDesc('loyalty_points');

        if ($request->filled('q')) {
            $q = $request->string('q');
            $query->where(function ($builder) use ($q) {
                $builder->where('name', 'like', "%{$q}%")
                    ->orWhere('email', 'like', "%{$q}%");
            });
        }

        return response()->json($query->paginate(20));
    }

    public function adjust(Request $request, User $user, LoyaltyService $loyalty)
    {
        abort_unless($user->role === 'customer', 404);

        $data = $request->validate([
            'points' => ['required', 'integer', 'not_in:0'],
            'description' => ['nullable', 'string', 'max:255'],
        ]);

        $tx = $loyalty->adjust(
            $user,
            $data['points'],
            'adjust',
            $data['description'] ?? 'Ajustement admin'
        );

        return response()->json([
            'data' => [
                'transaction' => $tx,
                'user' => $user->fresh(),
            ],
        ]);
    }
}
