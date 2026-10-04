<?php

namespace App\Services;

use App\Models\AppNotification;
use App\Models\LoyaltyTransaction;
use App\Models\Order;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class LoyaltyService
{
    public const POINTS_NOTIFICATION_TITLE = 'Points fidélité KINOVA';

    public static function tierFor(int $points): string
    {
        $s = AppSettings::all();

        return match (true) {
            $points >= $s['tier_vip_points'] => 'vip',
            $points >= $s['tier_gold_points'] => 'gold',
            $points >= $s['tier_silver_points'] => 'silver',
            default => 'standard',
        };
    }

    public function adjust(User $user, int $points, string $type, ?string $description = null, ?Order $order = null): LoyaltyTransaction
    {
        return DB::transaction(function () use ($user, $points, $type, $description, $order) {
            $user = User::query()->lockForUpdate()->findOrFail($user->id);
            $newBalance = max(0, $user->loyalty_points + $points);
            $applied = $newBalance - $user->loyalty_points;

            $user->update([
                'loyalty_points' => $newBalance,
                'vip_tier' => self::tierFor($newBalance),
            ]);

            // Points réellement appliqués (solde jamais négatif) : l'historique reste égal au solde.
            return LoyaltyTransaction::query()->create([
                'user_id' => $user->id,
                'points' => $applied,
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

        if (! AppSettings::loyaltyEnabled()) {
            return null;
        }

        $points = AppSettings::pointsForAmount((float) $order->total);
        if ($points <= 0) {
            return null;
        }

        // Verrou sur le client : deux validations simultanées de la livraison n'attribuent les points qu'une fois.
        [$user, $tx] = DB::transaction(function () use ($order, $points) {
            $user = User::query()->lockForUpdate()->find($order->user_id);
            if (! $user) {
                return [null, null];
            }

            $already = LoyaltyTransaction::query()
                ->where('order_id', $order->id)
                ->where('type', 'earn')
                ->exists();
            if ($already) {
                return [$user, null];
            }

            return [$user, $this->adjust(
                $user,
                $points,
                'earn',
                "Points gagnés commande {$order->reference}",
                $order
            )];
        });

        if (! $user || ! $tx) {
            return null;
        }

        app(NotificationService::class)->notifyUser(
            $user,
            self::POINTS_NOTIFICATION_TITLE,
            "Vous avez gagné {$points} ".($points > 1 ? 'points' : 'point')." VIP avec votre commande {$order->reference} (".AppSettings::render('{montant} = {points}').').',
            'vip',
            'star',
            ['order_reference' => $order->reference, 'points' => $points]
        );

        return $tx;
    }
}
