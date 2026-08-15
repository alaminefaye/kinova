<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Spatie\Permission\Models\Permission;

class PermissionController extends Controller
{
    public function index()
    {
        $descriptions = [
            'manage-products' => [
                'module' => 'Catalogue & Produits',
                'label' => 'Gestion des Produits',
                'description' => 'Créer, modifier et supprimer des produits, photos et stocks.',
            ],
            'view-products' => [
                'module' => 'Catalogue & Produits',
                'label' => 'Consulter les Produits',
                'description' => 'Accès en lecture seule au catalogue et fiches produits.',
            ],
            'manage-categories' => [
                'module' => 'Catalogue & Produits',
                'label' => 'Gestion des Catégories',
                'description' => 'Créer, ordonner et modifier les univers et catégories.',
            ],
            'manage-orders' => [
                'module' => 'Commandes & Ventes',
                'label' => 'Gestion des Commandes',
                'description' => 'Traiter les commandes, modifier le statut (expédié, livré) et gérer les annulations.',
            ],
            'view-orders' => [
                'module' => 'Commandes & Ventes',
                'label' => 'Consulter les Commandes',
                'description' => 'Voir l’historique des commandes et les détails clients.',
            ],
            'manage-slides' => [
                'module' => 'Marketing & Vitrine',
                'label' => 'Slider Accueil',
                'description' => 'Gérer les bannières publicitaires et promotions en page d’accueil.',
            ],
            'manage-notifications' => [
                'module' => 'Marketing & Vitrine',
                'label' => 'Notifications Push & In-App',
                'description' => 'Diffuser des annonces ciblées ou globales à tous les utilisateurs.',
            ],
            'manage-messages' => [
                'module' => 'Marketing & Vitrine',
                'label' => 'Support & Messages',
                'description' => 'Lire et traiter les demandes envoyées via le formulaire de contact.',
            ],
            'manage-loyalty' => [
                'module' => 'Fidélité VIP',
                'label' => 'Gestion Fidélité',
                'description' => 'Consulter les soldes de points et ajuster manuellement les points VIP.',
            ],
            'manage-users' => [
                'module' => 'Administration & Sécurité',
                'label' => 'Gestion des Utilisateurs',
                'description' => 'Créer, modifier, bloquer/débloquer et supprimer des comptes.',
            ],
            'manage-roles' => [
                'module' => 'Administration & Sécurité',
                'label' => 'Gestion des Rôles & Droits',
                'description' => 'Créer de nouveaux rôles et configurer leurs permissions.',
            ],
        ];

        $permissions = Permission::query()
            ->orderBy('id')
            ->get()
            ->map(function (Permission $p) use ($descriptions) {
                $meta = $descriptions[$p->name] ?? [
                    'module' => 'Autre',
                    'label' => $p->name,
                    'description' => $p->name,
                ];

                return [
                    'id' => $p->id,
                    'name' => $p->name,
                    'module' => $meta['module'],
                    'label' => $meta['label'],
                    'description' => $meta['description'],
                ];
            });

        // Groupement par module pour affichage facile dans l'UI
        $grouped = $permissions->groupBy('module');

        return response()->json([
            'all' => $permissions,
            'grouped' => $grouped,
        ]);
    }
}
