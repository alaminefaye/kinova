<?php

namespace App\Http\Controllers\Api\Customer;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\Rules\Password;
use Illuminate\Validation\ValidationException;
use Laravel\Sanctum\PersonalAccessToken;

class ProfileController extends Controller
{
    public function show(Request $request)
    {
        return response()->json([
            'data' => $this->payload($request->user()),
        ]);
    }

    public function update(Request $request)
    {
        $user = $request->user();

        $data = $request->validate([
            'name' => ['sometimes', 'string', 'max:120'],
            'phone' => ['sometimes', 'string', 'max:40', 'unique:users,phone,'.$user->id],
            'address' => ['nullable', 'string', 'max:255'],
            'city' => ['nullable', 'string', 'max:120'],
            'email' => ['nullable', 'email', 'max:160', 'unique:users,email,'.$user->id],
            'password' => ['nullable', 'confirmed', Password::defaults()],
            'current_password' => ['nullable', 'string'],
        ]);

        if (! empty($data['password'])) {
            if (empty($data['current_password']) || ! Hash::check($data['current_password'], $user->password)) {
                throw ValidationException::withMessages([
                    'current_password' => ['Mot de passe actuel incorrect.'],
                ]);
            }
        } else {
            unset($data['password']);
        }

        unset($data['current_password']);

        // Email vide → null
        if (array_key_exists('email', $data) && ($data['email'] === '' || $data['email'] === null)) {
            $data['email'] = null;
        }

        $user->update($data);

        if (! empty($data['password'])) {
            $current = $user->currentAccessToken();
            $user->tokens()
                ->when($current instanceof PersonalAccessToken, fn ($q) => $q->whereKeyNot($current->getKey()))
                ->delete();
        }

        return response()->json(['data' => $this->payload($user->fresh())]);
    }

    public function uploadAvatar(Request $request)
    {
        $user = $request->user();

        $request->validate([
            'avatar' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ]);

        $file = $request->file('avatar');
        $name = Str::uuid().'.'.$file->extension();
        $path = $file->storeAs('avatars', $name, 'public');

        // URL absolue utilisable par l'app mobile
        $url = $this->absoluteUrl(Storage::disk('public')->url($path));

        $this->deleteStoredAvatar($user->avatar_url);

        $user->update(['avatar_url' => $url]);

        return response()->json(['data' => $this->payload($user->fresh())]);
    }

    public function destroy(Request $request)
    {
        $data = $request->validate([
            'confirmation_code' => ['required', 'string'],
        ]);

        if (strtolower(trim($data['confirmation_code'])) !== 'kinovaci') {
            throw ValidationException::withMessages([
                'confirmation_code' => ['Code incorrect. Tapez « kinovaci » pour confirmer.'],
            ]);
        }

        $user = $request->user();

        if ($user->isAdmin()) {
            throw ValidationException::withMessages([
                'confirmation_code' => ['Un compte administrateur ne peut pas être supprimé ici.'],
            ]);
        }

        // Révoque les tokens Sanctum
        $user->tokens()->delete();

        $this->deleteStoredAvatar($user->avatar_url);

        $user->delete();

        return response()->json([
            'message' => 'Votre compte a été définitivement supprimé.',
        ]);
    }

    /** Supprime uniquement un fichier avatars/<uuid>.<ext> généré par uploadAvatar. */
    private function deleteStoredAvatar(?string $url): void
    {
        $path = (string) parse_url((string) $url, PHP_URL_PATH);
        if (preg_match('#/storage/(avatars/[0-9a-f-]{36}\.(?:jpe?g|png|webp|gif))$#i', $path, $m)) {
            Storage::disk('public')->delete($m[1]);
        }
    }

    private function payload($user): array
    {
        $roleNames = $user->roles->pluck('name')->toArray();
        if (empty($roleNames) && $user->role) {
            $roleNames = [$user->role];
        }

        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'avatar_url' => $this->absoluteUrl($user->avatar_url),
            'address' => $user->address,
            'city' => $user->city,
            'loyalty_points' => $user->loyalty_points,
            'vip_tier' => $user->vip_tier,
            'role' => $user->role,
            'roles' => $roleNames,
            'permissions' => $user->getAllPermissions()->pluck('name')->toArray(),
        ];
    }

    private function absoluteUrl(?string $url): ?string
    {
        if ($url === null || trim($url) === '') {
            return null;
        }

        if (str_starts_with($url, 'http://') || str_starts_with($url, 'https://')) {
            return $url;
        }

        return url($url);
    }
}
