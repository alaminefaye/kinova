<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;

class UserController extends Controller
{
    public function index(Request $request)
    {
        $query = User::query()
            ->withCount('orders')
            ->orderByDesc('created_at');

        if ($request->filled('q')) {
            $q = $request->string('q');
            $query->where(function ($b) use ($q) {
                $b->where('name', 'like', "%{$q}%")
                    ->orWhere('email', 'like', "%{$q}%")
                    ->orWhere('phone', 'like', "%{$q}%");
            });
        }

        if ($request->filled('role')) {
            $query->where('role', $request->string('role'));
        }

        if ($request->filled('status')) {
            $status = $request->string('status');
            if ($status === 'blocked') {
                $query->where('is_blocked', true);
            } elseif ($status === 'active') {
                $query->where('is_blocked', false);
            }
        }

        return response()->json($query->paginate(20));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'email' => ['required', 'email', 'max:160', 'unique:users,email'],
            'password' => ['required', 'string', Password::defaults()],
            'role' => ['required', 'string', Rule::in(['admin', 'customer'])],
            'phone' => ['nullable', 'string', 'max:40'],
            'address' => ['nullable', 'string', 'max:255'],
            'city' => ['nullable', 'string', 'max:100'],
            'vip_tier' => ['nullable', 'string', Rule::in(['standard', 'gold', 'platinum', 'diamond'])],
            'loyalty_points' => ['nullable', 'integer', 'min:0'],
            'is_blocked' => ['nullable', 'boolean'],
        ]);

        $user = User::query()->create([
            'name' => $data['name'],
            'email' => $data['email'],
            'password' => $data['password'],
            'role' => $data['role'],
            'phone' => $data['phone'] ?? null,
            'address' => $data['address'] ?? null,
            'city' => $data['city'] ?? null,
            'vip_tier' => $data['vip_tier'] ?? 'standard',
            'loyalty_points' => $data['loyalty_points'] ?? 0,
            'is_blocked' => $data['is_blocked'] ?? false,
        ]);

        return response()->json([
            'message' => 'Utilisateur créé avec succès.',
            'user' => $user->fresh(),
        ], 201);
    }

    public function show(User $user)
    {
        $user->loadCount('orders');

        return response()->json([
            'user' => $user,
            'recent_orders' => $user->orders()->latest()->take(5)->get(),
        ]);
    }

    public function update(Request $request, User $user)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'email' => ['required', 'email', 'max:160', Rule::unique('users', 'email')->ignore($user->id)],
            'password' => ['nullable', 'string', Password::defaults()],
            'role' => ['required', 'string', Rule::in(['admin', 'customer'])],
            'phone' => ['nullable', 'string', 'max:40'],
            'address' => ['nullable', 'string', 'max:255'],
            'city' => ['nullable', 'string', 'max:100'],
            'vip_tier' => ['nullable', 'string', Rule::in(['standard', 'gold', 'platinum', 'diamond'])],
            'loyalty_points' => ['nullable', 'integer', 'min:0'],
            'is_blocked' => ['nullable', 'boolean'],
        ]);

        $updateData = [
            'name' => $data['name'],
            'email' => $data['email'],
            'role' => $data['role'],
            'phone' => $data['phone'] ?? null,
            'address' => $data['address'] ?? null,
            'city' => $data['city'] ?? null,
            'vip_tier' => $data['vip_tier'] ?? 'standard',
            'loyalty_points' => $data['loyalty_points'] ?? 0,
        ];

        if (isset($data['is_blocked'])) {
            $updateData['is_blocked'] = (bool) $data['is_blocked'];
            if ($updateData['is_blocked']) {
                $user->tokens()->delete();
            }
        }

        if (! empty($data['password'])) {
            $updateData['password'] = $data['password'];
        }

        $user->update($updateData);

        return response()->json([
            'message' => 'Utilisateur mis à jour avec succès.',
            'user' => $user->fresh(),
        ]);
    }

    public function toggleBlock(User $user)
    {
        $user->is_blocked = ! $user->is_blocked;
        $user->save();

        if ($user->is_blocked) {
            $user->tokens()->delete();
        }

        $statusLabel = $user->is_blocked ? 'bloqué' : 'débloqué';

        return response()->json([
            'message' => "Le compte de {$user->name} a été {$statusLabel}.",
            'user' => $user,
        ]);
    }

    public function destroy(Request $request, User $user)
    {
        if ($request->user()->id === $user->id) {
            return response()->json(['message' => 'Vous ne pouvez pas supprimer votre propre compte admin.'], 422);
        }

        $user->tokens()->delete();
        $user->delete();

        return response()->json(['message' => 'Utilisateur supprimé avec succès.']);
    }
}
