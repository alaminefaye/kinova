<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;
use Spatie\Permission\PermissionRegistrar;

class RoleController extends Controller
{
    public function index()
    {
        $roles = Role::query()
            ->with('permissions:id,name')
            ->withCount('users')
            ->orderBy('id')
            ->get()
            ->map(function (Role $role) {
                return [
                    'id' => $role->id,
                    'name' => $role->name,
                    'guard_name' => $role->guard_name,
                    'users_count' => $role->users_count,
                    'permissions' => $role->permissions->pluck('name'),
                    'created_at' => $role->created_at?->toIso8601String(),
                ];
            });

        return response()->json($roles);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:60', 'unique:roles,name'],
            'permissions' => ['nullable', 'array'],
            'permissions.*' => ['string', 'exists:permissions,name'],
        ]);

        $role = Role::create([
            'name' => strtolower(trim($data['name'])),
            'guard_name' => 'web',
        ]);

        if (! empty($data['permissions'])) {
            $role->syncPermissions($data['permissions']);
        }

        app()[PermissionRegistrar::class]->forgetCachedPermissions();

        return response()->json([
            'message' => 'Rôle créé avec succès.',
            'role' => [
                'id' => $role->id,
                'name' => $role->name,
                'permissions' => $role->permissions->pluck('name'),
                'users_count' => 0,
            ],
        ], 201);
    }

    public function show(Role $role)
    {
        $role->load('permissions:id,name')->loadCount('users');

        return response()->json([
            'id' => $role->id,
            'name' => $role->name,
            'guard_name' => $role->guard_name,
            'users_count' => $role->users_count,
            'permissions' => $role->permissions->pluck('name'),
        ]);
    }

    public function update(Request $request, Role $role)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:60', Rule::unique('roles', 'name')->ignore($role->id)],
            'permissions' => ['nullable', 'array'],
            'permissions.*' => ['string', 'exists:permissions,name'],
        ]);

        // Empêcher de renommer le rôle super-admin
        if ($role->name === 'super-admin' && $data['name'] !== 'super-admin') {
            return response()->json(['message' => 'Le rôle super-admin ne peut pas être renommé.'], 422);
        }

        $role->update([
            'name' => strtolower(trim($data['name'])),
        ]);

        if (isset($data['permissions'])) {
            // Super-admin garde toujours toutes les permissions
            if ($role->name === 'super-admin') {
                $role->syncPermissions(Permission::all());
            } else {
                $role->syncPermissions($data['permissions']);
            }
        }

        app()[PermissionRegistrar::class]->forgetCachedPermissions();

        return response()->json([
            'message' => 'Rôle mis à jour avec succès.',
            'role' => [
                'id' => $role->id,
                'name' => $role->name,
                'permissions' => $role->fresh()->permissions->pluck('name'),
                'users_count' => $role->users()->count(),
            ],
        ]);
    }

    public function destroy(Role $role)
    {
        if (in_array($role->name, ['super-admin', 'admin', 'customer'])) {
            return response()->json([
                'message' => 'Les rôles système par défaut ne peuvent pas être supprimés.',
            ], 422);
        }

        if ($role->users()->count() > 0) {
            return response()->json([
                'message' => "Ce rôle est actuellement attribué à {$role->users()->count()} utilisateur(s). Veuillez réassigner ces utilisateurs avant de supprimer.",
            ], 422);
        }

        $role->delete();

        app()[PermissionRegistrar::class]->forgetCachedPermissions();

        return response()->json(['message' => 'Rôle supprimé avec succès.']);
    }
}
