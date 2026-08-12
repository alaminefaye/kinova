<?php

namespace App\Http\Controllers\Api\Customer;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(Request $request)
    {
        $notifications = AppNotification::query()
            ->where('user_id', $request->user()->id)
            ->latest()
            ->paginate(30);

        $unread = AppNotification::query()
            ->where('user_id', $request->user()->id)
            ->where('is_read', false)
            ->count();

        return response()->json([
            'unread_count' => $unread,
            ...$notifications->toArray(),
        ]);
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
