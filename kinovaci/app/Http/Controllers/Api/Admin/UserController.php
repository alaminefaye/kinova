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
            ->with(['roles:id,name', 'permissions:id,name'])
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
            $roleName = $request->string('role')->toString();
            $query->where(function ($b) use ($roleName) {
                $b->whereHas('roles', fn ($r) => $r->where('name', $roleName))
                    ->orWhere('role', $roleName);
            });
        }

        if ($request->filled('status')) {
            $status = $request->string('status');
            if ($status === 'blocked') {
                $query->where('is_blocked', true);
            } elseif ($status === 'active') {
                $query->where('is_blocked', false);
            }
        }

        $paginator = $query->paginate(20);

        $paginator->getCollection()->transform(function (User $user) {
            $roleNames = $user->roles->pluck('name')->toArray();
            if (empty($roleNames) && $user->role) {
                $roleNames = [$user->role];
            }

            return array_merge($user->toArray(), [
                'roles' => $roleNames,
                'permissions' => $user->permissions->pluck('name')->toArray(),
            ]);
        });

        return response()->json($paginator);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'email' => ['required', 'email', 'max:160', 'unique:users,email'],
            'password' => ['required', 'string', Password::defaults()],
            'role' => ['nullable', 'string'],
            'roles' => ['nullable', 'array'],
            'roles.*' => ['string'],
            'permissions' => ['nullable', 'array'],
            'permissions.*' => ['string'],
            'phone' => ['nullable', 'string', 'max:40'],
            'address' => ['nullable', 'string', 'max:255'],
            'city' => ['nullable', 'string', 'max:100'],
            'vip_tier' => ['nullable', 'string', Rule::in(['standard', 'gold', 'platinum', 'diamond'])],
            'loyalty_points' => ['nullable', 'integer', 'min:0'],
            'is_blocked' => ['nullable', 'boolean'],
        ]);

        // Détermination des rôles (défaut 'customer' si non spécifié)
        $assignedRoles = ! empty($data['roles'])
            ? $data['roles']
            : (! empty($data['role']) ? [$data['role']] : ['customer']);

        $primaryRole = in_array('super-admin', $assignedRoles)
            || in_array('admin', $assignedRoles)
            || in_array('manager', $assignedRoles)
            || in_array('support', $assignedRoles)
            ? 'admin'
            : 'customer';

        $user = User::query()->create([
            'name' => $data['name'],
            'email' => $data['email'],
            'password' => $data['password'],
            'role' => $primaryRole,
            'phone' => $data['phone'] ?? null,
            'address' => $data['address'] ?? null,
            'city' => $data['city'] ?? null,
            'vip_tier' => $data['vip_tier'] ?? 'standard',
            'loyalty_points' => $data['loyalty_points'] ?? 0,
            'is_blocked' => $data['is_blocked'] ?? false,
        ]);

        if (! empty($assignedRoles)) {
            $user->syncRoles($assignedRoles);
        }

        if (isset($data['permissions'])) {
            $user->syncPermissions($data['permissions']);
        }

        $user->load(['roles:id,name', 'permissions:id,name'])->loadCount('orders');

        return response()->json([
            'message' => 'Utilisateur créé avec succès.',
            'user' => array_merge($user->toArray(), [
                'roles' => $user->roles->pluck('name')->toArray(),
                'permissions' => $user->permissions->pluck('name')->toArray(),
            ]),
        ], 201);
    }

    public function show(User $user)
    {
        $user->load(['roles:id,name', 'permissions:id,name'])->loadCount('orders');

        $roleNames = $user->roles->pluck('name')->toArray();
        if (empty($roleNames) && $user->role) {
            $roleNames = [$user->role];
        }

        return response()->json([
            'user' => array_merge($user->toArray(), [
                'roles' => $roleNames,
                'permissions' => $user->permissions->pluck('name')->toArray(),
            ]),
            'recent_orders' => $user->orders()->latest()->take(5)->get(),
        ]);
    }

    public function update(Request $request, User $user)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'email' => ['required', 'email', 'max:160', Rule::unique('users', 'email')->ignore($user->id)],
            'password' => ['nullable', 'string', Password::defaults()],
            'role' => ['nullable', 'string'],
            'roles' => ['nullable', 'array'],
            'roles.*' => ['string'],
            'permissions' => ['nullable', 'array'],
            'permissions.*' => ['string'],
            'phone' => ['nullable', 'string', 'max:40'],
            'address' => ['nullable', 'string', 'max:255'],
            'city' => ['nullable', 'string', 'max:100'],
            'vip_tier' => ['nullable', 'string', Rule::in(['standard', 'gold', 'platinum', 'diamond'])],
            'loyalty_points' => ['nullable', 'integer', 'min:0'],
            'is_blocked' => ['nullable', 'boolean'],
        ]);

        $assignedRoles = ! empty($data['roles'])
            ? $data['roles']
            : (! empty($data['role']) ? [$data['role']] : null);

        $updateData = [
            'name' => $data['name'],
            'email' => $data['email'],
            'phone' => $data['phone'] ?? null,
            'address' => $data['address'] ?? null,
            'city' => $data['city'] ?? null,
            'vip_tier' => $data['vip_tier'] ?? 'standard',
            'loyalty_points' => $data['loyalty_points'] ?? 0,
        ];

        if ($assignedRoles !== null) {
            $updateData['role'] = in_array('super-admin', $assignedRoles)
                || in_array('admin', $assignedRoles)
                || in_array('manager', $assignedRoles)
                || in_array('support', $assignedRoles)
                ? 'admin'
                : 'customer';
        }

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

        if ($assignedRoles !== null) {
            $user->syncRoles($assignedRoles);
        }

        if (isset($data['permissions'])) {
            $user->syncPermissions($data['permissions']);
        }

        $user->load(['roles:id,name', 'permissions:id,name'])->loadCount('orders');

        return response()->json([
            'message' => 'Utilisateur mis à jour avec succès.',
            'user' => array_merge($user->toArray(), [
                'roles' => $user->roles->pluck('name')->toArray(),
                'permissions' => $user->permissions->pluck('name')->toArray(),
            ]),
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
