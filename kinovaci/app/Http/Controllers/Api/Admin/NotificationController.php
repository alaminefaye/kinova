<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use App\Services\NotificationService;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(Request $request)
    {
        $query = AppNotification::query()->with('user:id,name,email')->latest();

        if ($request->filled('category')) {
            $query->where('category', $request->string('category'));
        }

        return response()->json($query->paginate(30));
    }

    public function store(Request $request, NotificationService $notifications)
    {
        $data = $request->validate([
            'title' => ['required', 'string', 'max:160'],
            'message' => ['required', 'string', 'max:2000'],
            'category' => ['required', 'in:order,vip,promo,system'],
            'icon' => ['nullable', 'string', 'max:40'],
            'user_id' => ['nullable', 'exists:users,id'],
            'broadcast' => ['boolean'],
        ]);

        if (! empty($data['broadcast'])) {
            $created = $notifications->broadcast(
                $data['title'],
                $data['message'],
                $data['category'],
                $data['icon'] ?? 'bell',
            );

            return response()->json([
                'message' => 'Notification diffusée.',
                'count' => $created->count(),
            ], 201);
        }

        abort_unless(! empty($data['user_id']), 422, 'user_id requis si broadcast=false');

        $user = \App\Models\User::query()->findOrFail($data['user_id']);
        $notification = $notifications->notifyUser(
            $user,
            $data['title'],
            $data['message'],
            $data['category'],
            $data['icon'] ?? 'bell',
        );

        return response()->json(['data' => $notification], 201);
    }

    public function destroy(AppNotification $appNotification)
    {
        $appNotification->delete();

        return response()->json(['message' => 'Notification supprimée.']);
    }
}
