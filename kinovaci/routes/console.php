<?php

use App\Models\AppNotification;
use App\Models\DeviceToken;
use App\Models\Order;
use App\Models\User;
use App\Services\FirebasePushService;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\PersonalAccessToken;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Artisan::command('admin:list', function () {
    $users = User::query()->with('roles')->get()
        ->filter(fn (User $u) => $u->hasAnyRole(['super-admin', 'admin', 'manager', 'support']) || $u->role === 'admin');

    $this->table(
        ['ID', 'Email', 'Nom', 'Rôles', 'Accès dashboard', 'Sessions actives', 'Dernière activité'],
        $users->map(fn (User $u) => [
            $u->id,
            $u->email,
            $u->name,
            $u->roles->pluck('name')->implode(', ') ?: $u->role,
            $u->isSuperAdmin() ? 'OUI' : 'non',
            $u->tokens()->count(),
            optional($u->tokens()->max('last_used_at'), fn ($d) => (string) $d) ?? '—',
        ])->values()->all(),
    );
})->purpose('Lister les comptes ayant un rôle admin et leur accès au dashboard');

Artisan::command('admin:password {email}', function (string $email) {
    $user = User::query()->where('email', $email)->first();
    if (! $user) {
        $this->error("Compte {$email} introuvable.");

        return 1;
    }

    $password = (string) $this->secret('Nouveau mot de passe (12 caractères minimum)');
    if (mb_strlen($password) < 12) {
        $this->error('Mot de passe trop court (12 caractères minimum).');

        return 1;
    }
    if ($password !== (string) $this->secret('Confirmez le mot de passe')) {
        $this->error('Les deux mots de passe ne correspondent pas.');

        return 1;
    }

    $user->forceFill(['password' => Hash::make($password)])->save();
    $revoked = $user->tokens()->delete();
    $this->info("Mot de passe changé pour {$email}. {$revoked} session(s) déconnectée(s).");
})->purpose('Changer le mot de passe d’un compte et déconnecter toutes ses sessions');

Artisan::command('admin:grant {email} {--remove : Retirer le rôle super-admin}', function (string $email) {
    $user = User::query()->where('email', $email)->first();
    if (! $user) {
        $this->error("Compte {$email} introuvable.");

        return 1;
    }

    if ($this->option('remove')) {
        $user->removeRole('super-admin');
        $user->tokens()->delete();
        $this->info("Rôle super-admin retiré à {$email} (sessions déconnectées).");

        return 0;
    }

    $user->assignRole('super-admin');
    $this->info("{$email} est maintenant super-admin (accès dashboard).");
})->purpose('Donner (ou retirer avec --remove) le rôle super-admin');

Artisan::command('admin:logout-all {--everyone : Déconnecter aussi tous les clients}', function () {
    $query = PersonalAccessToken::query();
    if (! $this->option('everyone')) {
        $query->whereIn('tokenable_id', User::role('super-admin')->pluck('id'))
            ->where('tokenable_type', User::class);
    }
    $this->info($query->delete().' session(s) supprimée(s).');
})->purpose('Déconnecter toutes les sessions admin (ou tout le monde avec --everyone)');

Artisan::command('push:test {user? : Email, téléphone ou ID du compte} {--order= : Référence de commande à analyser}', function (FirebasePushService $push) {
    $path = $push->credentialsPath();
    $this->line('Clé Firebase : '.($path ?? '(FIREBASE_CREDENTIALS non défini)'));
    $this->line('  → fichier présent : '.($path && is_file($path) ? 'OUI' : 'NON ❌'));
    $this->line('  → push activé : '.($push->isEnabled() ? 'OUI' : 'NON ❌'));
    $this->line('Jetons enregistrés (tous comptes) : '.DeviceToken::count());

    if ($ref = $this->option('order')) {
        $order = Order::query()->where('reference', $ref)->first();
        if (! $order) {
            $this->error("Commande {$ref} introuvable.");
        } else {
            $this->line("Commande {$ref} : compte client = ".($order->user_id ?? 'AUCUN (commande invité → pas de notif client)'));
            $this->line('  → notifications créées pour ce compte depuis : '.AppNotification::query()
                ->where('user_id', $order->user_id)
                ->where('created_at', '>=', $order->created_at)
                ->count());
        }
    }

    $key = $this->argument('user');
    if (! $key) {
        return;
    }

    $user = User::query()->where('email', $key)->orWhere('phone', $key)->orWhere('id', $key)->first();
    if (! $user) {
        $this->error("Compte {$key} introuvable.");

        return;
    }

    $tokens = DeviceToken::query()->where('user_id', $user->id)->get();
    $this->line("Compte #{$user->id} {$user->name} : ".$tokens->count().' appareil(s)');
    foreach ($tokens as $t) {
        $this->line("  - {$t->platform} · mis à jour {$t->updated_at}");
    }
    if ($tokens->isEmpty()) {
        $this->warn('Aucun appareil : ouvrez l\'app connecté avec ce compte et acceptez les notifications.');

        return;
    }

    $sent = $push->sendToUser($user, 'Test KINOVA', 'Si vous lisez ceci, les notifications fonctionnent.');
    $sent > 0
        ? $this->info("Push envoyé à {$sent} appareil(s).")
        : $this->error('Échec : '.($push->lastError ?? 'inconnu'));
})->purpose('Diagnostiquer les notifications push');
