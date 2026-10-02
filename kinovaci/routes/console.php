<?php

use App\Models\AppNotification;
use App\Models\DeviceToken;
use App\Models\Order;
use App\Models\User;
use App\Services\FirebasePushService;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

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
