<?php

namespace App\Services;

use App\Models\DeviceToken;
use App\Models\User;
use Illuminate\Support\Facades\Log;
use Kreait\Firebase\Contract\Messaging;
use Kreait\Firebase\Exception\MessagingException;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification as FcmNotification;

class FirebasePushService
{
    /** Doivent correspondre aux ressources de l'app (res/raw, Runner/*.caf) et au canal Android. */
    private const ANDROID_CHANNEL = 'kinova_alerts';

    private const SOUND = 'kinova_notification';

    /** Logo affiché dans la notification : URL publique, joignable par les téléphones. */
    private const LOGO_URL = 'https://kinovaci.com/images/logo.png';

    public function sendToUser(
        User $user,
        string $title,
        string $message,
        string $category = 'system',
        ?array $data = null,
    ): int {
        if (! $this->isEnabled()) {
            return 0;
        }

        $messaging = $this->messaging();
        if ($messaging === null) {
            return 0;
        }

        $tokens = DeviceToken::query()
            ->where('user_id', $user->id)
            ->pluck('token');

        if ($tokens->isEmpty()) {
            return 0;
        }

        $payload = $this->stringifyData(array_merge($data ?? [], [
            'category' => $category,
        ]));

        $sent = 0;
        foreach ($tokens as $token) {
            if ($this->sendToToken($messaging, $token, $title, $message, $payload)) {
                $sent++;
            }
        }

        return $sent;
    }

    public function isEnabled(): bool
    {
        if (! filter_var(env('FIREBASE_PUSH_ENABLED', true), FILTER_VALIDATE_BOOL)) {
            return false;
        }

        $credentials = config('firebase.projects.app.credentials');
        if (! is_string($credentials) || $credentials === '') {
            return false;
        }

        return is_file($this->resolveCredentialsPath($credentials));
    }

    private function messaging(): ?Messaging
    {
        try {
            return app(Messaging::class);
        } catch (\Throwable $e) {
            Log::warning('Firebase Messaging indisponible', [
                'error' => $e->getMessage(),
            ]);

            return null;
        }
    }

    private function sendToToken(
        Messaging $messaging,
        string $token,
        string $title,
        string $message,
        array $data,
    ): bool {
        try {
            $cloudMessage = CloudMessage::new()
                ->withToken($token)
                ->withNotification(FcmNotification::create($title, $message, self::LOGO_URL))
                ->withData($data)
                ->withAndroidConfig([
                    'notification' => [
                        'channel_id' => self::ANDROID_CHANNEL,
                        'sound' => self::SOUND,
                        'icon' => 'ic_notification',
                        'color' => '#C5A080',
                    ],
                ])
                ->withApnsConfig([
                    'payload' => [
                        'aps' => [
                            'sound' => self::SOUND.'.caf',
                        ],
                    ],
                ])
                // Après les configs Android/APNs, sinon elles écrasent la priorité.
                ->withHighestPossiblePriority();

            $messaging->send($cloudMessage);

            return true;
        } catch (MessagingException $e) {
            if ($this->isInvalidToken($e)) {
                DeviceToken::query()->where('token', $token)->delete();
            } else {
                Log::warning('Échec envoi FCM', [
                    'token' => substr($token, 0, 16).'…',
                    'error' => $e->getMessage(),
                ]);
            }

            return false;
        } catch (\Throwable $e) {
            Log::warning('Erreur envoi FCM', ['error' => $e->getMessage()]);

            return false;
        }
    }

    private function isInvalidToken(MessagingException $e): bool
    {
        $message = strtolower($e->getMessage());

        return str_contains($message, 'not found')
            || str_contains($message, 'unregistered')
            || str_contains($message, 'invalid')
            || str_contains($message, 'registration token');
    }

    /**
     * @param  array<string, mixed>  $data
     * @return array<string, string>
     */
    private function stringifyData(array $data): array
    {
        $out = [];
        foreach ($data as $key => $value) {
            if ($value === null) {
                continue;
            }
            $out[(string) $key] = is_scalar($value)
                ? (string) $value
                : json_encode($value, JSON_UNESCAPED_UNICODE);
        }

        return $out;
    }

    private function resolveCredentialsPath(string $path): string
    {
        if (str_starts_with($path, '/')) {
            return $path;
        }

        return base_path($path);
    }
}
