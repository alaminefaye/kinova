<?php

namespace App\Http\Controllers\Api\Customer;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\NotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(Request $request, NotificationService $notifications)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'phone' => ['required', 'string', 'max:40', 'unique:users,phone'],
            'email' => ['nullable', 'email', 'max:160', 'unique:users,email'],
            'password' => ['required', 'confirmed', Password::defaults()],
        ]);

        $user = User::query()->create([
            'name' => $data['name'],
            'phone' => $data['phone'],
            'email' => $data['email'] ?? null,
            'password' => $data['password'],
            'role' => 'customer',
            'loyalty_points' => 0,
            'vip_tier' => 'standard',
        ]);

        $user->assignRole('customer');

        $notifications->notifyUser(
            $user,
            'Bienvenue chez KINOVA',
            'Votre compte est prêt. Profitez de vos avantages VIP dès vos premières commandes.',
            'vip',
            'sparkles'
        );

        $token = $user->createToken('kinova-mobile')->plainTextToken;

        $roleNames = $user->roles->pluck('name')->toArray();
        if (empty($roleNames) && $user->role) {
            $roleNames = [$user->role];
        }

        return response()->json([
            'token' => $token,
            'user' => array_merge($user->toArray(), [
                'roles' => $roleNames,
                'permissions' => $user->getAllPermissions()->pluck('name')->toArray(),
            ]),
        ], 201);
    }

    public function login(Request $request)
    {
        $data = $request->validate([
            // Accepte `login`, ou legacy `email` / `phone`
            'login' => ['nullable', 'string', 'max:160'],
            'email' => ['nullable', 'string', 'max:160'],
            'phone' => ['nullable', 'string', 'max:40'],
            'password' => ['required', 'string'],
        ]);

        $login = trim((string) ($data['login'] ?? $data['email'] ?? $data['phone'] ?? ''));

        if ($login === '') {
            throw ValidationException::withMessages([
                'login' => ['Indiquez votre email ou numéro de téléphone.'],
            ]);
        }

        $user = User::query()
            ->where(function ($query) use ($login) {
                $query->where('email', $login)->orWhere('phone', $login);
            })
            ->first();

        if (! $user || ! Hash::check($data['password'], $user->password)) {
            throw ValidationException::withMessages([
                'login' => ['Identifiants incorrects.'],
            ]);
        }

        if ($user->is_blocked) {
            throw ValidationException::withMessages([
                'login' => ['Votre compte a été bloqué par un administrateur.'],
            ]);
        }

        $token = $user->createToken('kinova-mobile')->plainTextToken;

        $roleNames = $user->roles->pluck('name')->toArray();
        if (empty($roleNames) && $user->role) {
            $roleNames = [$user->role];
        }

        return response()->json([
            'token' => $token,
            'user' => array_merge($user->toArray(), [
                'roles' => $roleNames,
                'permissions' => $user->getAllPermissions()->pluck('name')->toArray(),
            ]),
        ]);
    }
}
