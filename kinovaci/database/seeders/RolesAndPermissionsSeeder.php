<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;
use Spatie\Permission\PermissionRegistrar;

class RolesAndPermissionsSeeder extends Seeder
{
    public function run(): void
    {
        // Réinitialise le cache des permissions Spatie
        app()[PermissionRegistrar::class]->forgetCachedPermissions();

        // 1. Définition des permissions par module
        $permissionsByModule = [
            'Catalogue' => [
                'manage-products' => 'Créer, modifier et supprimer des produits',
                'view-products' => 'Consulter les produits et le catalogue',
                'manage-categories' => 'Créer, modifier et supprimer des catégories',
            ],
            'Commandes' => [
                'manage-orders' => 'Mettre à jour les statuts de commande et livraisons',
                'view-orders' => 'Consulter les commandes et détails',
            ],
            'Marketing & Vitrine' => [
                'manage-slides' => 'Gérer les diapositives du slider d’accueil',
                'manage-notifications' => 'Créer et envoyer des notifications',
                'manage-messages' => 'Consulter et traiter les messages de contact',
            ],
            'Fidélité VIP' => [
                'manage-loyalty' => 'Consulter et ajuster les points de fidélité VIP',
            ],
            'Administration & Sécurité' => [
                'manage-users' => 'Créer, modifier, bloquer et supprimer des utilisateurs',
                'manage-roles' => 'Gérer les rôles et attribuer des permissions',
            ],
        ];

        $allCreatedPermissions = [];
        foreach ($permissionsByModule as $module => $permissions) {
            foreach ($permissions as $name => $description) {
                $permission = Permission::query()->firstOrCreate(
                    ['name' => $name, 'guard_name' => 'web'],
                    ['name' => $name, 'guard_name' => 'web']
                );
                $allCreatedPermissions[$name] = $permission;
            }
        }

        // 2. Définition des Rôles par défaut
        $superAdminRole = Role::query()->firstOrCreate(
            ['name' => 'super-admin', 'guard_name' => 'web'],
            ['name' => 'super-admin', 'guard_name' => 'web']
        );
        $superAdminRole->syncPermissions(Permission::query()->where('guard_name', 'web')->get());

        $adminRole = Role::query()->firstOrCreate(
            ['name' => 'admin', 'guard_name' => 'web'],
            ['name' => 'admin', 'guard_name' => 'web']
        );
        $adminRole->syncPermissions([
            'manage-products',
            'view-products',
            'manage-categories',
            'manage-orders',
            'view-orders',
            'manage-slides',
            'manage-notifications',
            'manage-messages',
            'manage-loyalty',
            'manage-users',
            'manage-roles',
        ]);

        $managerRole = Role::query()->firstOrCreate(
            ['name' => 'manager', 'guard_name' => 'web'],
            ['name' => 'manager', 'guard_name' => 'web']
        );
        $managerRole->syncPermissions([
            'manage-products',
            'view-products',
            'manage-categories',
            'manage-orders',
            'view-orders',
            'manage-slides',
            'manage-messages',
        ]);

        $supportRole = Role::query()->firstOrCreate(
            ['name' => 'support', 'guard_name' => 'web'],
            ['name' => 'support', 'guard_name' => 'web']
        );
        $supportRole->syncPermissions([
            'view-orders',
            'view-products',
            'manage-messages',
            'manage-notifications',
        ]);

        $customerRole = Role::query()->firstOrCreate(
            ['name' => 'customer', 'guard_name' => 'web'],
            ['name' => 'customer', 'guard_name' => 'web']
        );

        // 3. Attribution aux utilisateurs existants
        $adminUser = User::query()->where('email', 'admin@kinova.test')->first();
        if ($adminUser) {
            $adminUser->syncRoles([$superAdminRole]);
        }

        $customerUser = User::query()->where('email', 'client@kinova.test')->first();
        if ($customerUser) {
            $customerUser->syncRoles([$customerRole]);
        }

        // Assigner le rôle customer à tout utilisateur sans rôle
        $usersWithoutRole = User::query()->whereDoesntHave('roles')->get();
        foreach ($usersWithoutRole as $u) {
            if ($u->role === 'admin') {
                $u->syncRoles([$adminRole]);
            } else {
                $u->syncRoles([$customerRole]);
            }
        }
    }
}
