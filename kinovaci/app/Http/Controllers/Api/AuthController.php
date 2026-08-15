<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $user = User::query()->where('email', $data['email'])->first();

        if (! $user || ! Hash::check($data['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Identifiants incorrects.'],
            ]);
        }

        if ($user->is_blocked) {
            throw ValidationException::withMessages([
                'email' => ['Votre compte a été bloqué par un administrateur.'],
            ]);
        }

        $token = $user->createToken('kinova')->plainTextToken;

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

    public function me(Request $request)
    {
        $user = $request->user();
        $roleNames = $user->roles->pluck('name')->toArray();
        if (empty($roleNames) && $user->role) {
            $roleNames = [$user->role];
        }

        return response()->json(array_merge($user->toArray(), [
            'roles' => $roleNames,
            'permissions' => $user->getAllPermissions()->pluck('name')->toArray(),
        ]));
    }

    public function logout(Request $request)
    {
        $request->user()?->currentAccessToken()?->delete();

        return response()->json(['message' => 'Déconnecté.']);
    }
}
