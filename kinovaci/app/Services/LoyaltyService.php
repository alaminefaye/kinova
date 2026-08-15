<?php

namespace App\Services;

use App\Models\AppNotification;
use App\Models\LoyaltyTransaction;
use App\Models\Order;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class LoyaltyService
{
    public static function tierFor(int $points): string
    {
        return match (true) {
            $points >= 100 => 'vip',     // >= 1 000 000 FCFA
            $points >= 50 => 'gold',     // >= 500 000 FCFA
            $points >= 20 => 'silver',   // >= 200 000 FCFA
            default => 'standard',
        };
    }

    public function adjust(User $user, int $points, string $type, ?string $description = null, ?Order $order = null): LoyaltyTransaction
    {
        return DB::transaction(function () use ($user, $points, $type, $description, $order) {
            $user = User::query()->lockForUpdate()->findOrFail($user->id);
            $newBalance = max(0, $user->loyalty_points + $points);

            $user->update([
                'loyalty_points' => $newBalance,
                'vip_tier' => self::tierFor($newBalance),
            ]);

            return LoyaltyTransaction::query()->create([
                'user_id' => $user->id,
                'points' => $points,
                'type' => $type,
                'description' => $description,
                'order_id' => $order?->id,
            ]);
        });
    }

    public function awardForDeliveredOrder(Order $order): ?LoyaltyTransaction
    {
        if (! $order->user_id || $order->status !== 'delivered') {
            return null;
        }

        $already = LoyaltyTransaction::query()
            ->where('order_id', $order->id)
            ->where('type', 'earn')
            ->exists();

        if ($already) {
            return null;
        }

        // Règle de fidélité : 10 000 FCFA dépensés = 1 point
        $points = (int) floor(((float) $order->total) / 10000);
        if ($points <= 0) {
            return null;
        }

        $user = $order->user ?? User::query()->find($order->user_id);
        if (! $user) {
            return null;
        }

        $tx = $this->adjust(
            $user,
            $points,
            'earn',
            "Points gagnés commande {$order->reference}",
            $order
        );

        app(NotificationService::class)->notifyUser(
            $user,
            'Points fidélité KINOVA',
            "Vous avez gagné {$points} point(s) VIP avec votre commande {$order->reference} (10 000 FCFA = 1 point).",
            'vip',
            'star',
            ['order_reference' => $order->reference, 'points' => $points]
        );

        return $tx;
    }
}
