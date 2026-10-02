<?php

namespace App\Http\Controllers\Api\Customer;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use App\Services\AppSettings;
use App\Services\LoyaltyService;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(Request $request)
    {
        $notifications = $this->visibleFor($request)
            ->latest()
            ->paginate(30);

        $unread = $this->visibleFor($request)
            ->where('is_read', false)
            ->count();

        return response()->json([
            'unread_count' => $unread,
            ...$notifications->toArray(),
        ]);
    }

    private function visibleFor(Request $request): Builder
    {
        return AppNotification::query()
            ->where('user_id', $request->user()->id)
            ->when(
                ! AppSettings::loyaltyEnabled(),
                fn (Builder $q) => $q->where('title', '!=', LoyaltyService::POINTS_NOTIFICATION_TITLE)
            );
    }

    public function markRead(Request $request, AppNotification $appNotification)
    {
        abort_unless($appNotification->user_id === $request->user()->id, 404);

        $appNotification->update(['is_read' => true]);

        return response()->json(['data' => $appNotification]);
    }

    public function markAllRead(Request $request)
    {
        AppNotification::query()
            ->where('user_id', $request->user()->id)
            ->where('is_read', false)
            ->update(['is_read' => true]);

        return response()->json(['message' => 'Toutes les notifications sont lues.']);
    }
}
