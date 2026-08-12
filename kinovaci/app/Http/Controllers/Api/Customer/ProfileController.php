<?php

namespace App\Http\Controllers\Api\Customer;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\Rules\Password;
use Illuminate\Validation\ValidationException;

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
            'avatar_url' => ['nullable', 'string', 'max:500'],
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

        return response()->json(['data' => $this->payload($user->fresh())]);
    }

    public function uploadAvatar(Request $request)
    {
        $user = $request->user();

        $request->validate([
            'avatar' => ['required', 'image', 'max:5120'],
        ]);

        $file = $request->file('avatar');
        $name = Str::uuid().'.'.$file->getClientOriginalExtension();
        $path = $file->storeAs('avatars', $name, 'public');

        // URL absolue utilisable par l'app mobile
        $url = $this->absoluteUrl(Storage::disk('public')->url($path));

        // Supprime l'ancienne image locale si possible
        if ($user->avatar_url && str_contains((string) $user->avatar_url, '/storage/avatars/')) {
            $oldPath = parse_url((string) $user->avatar_url, PHP_URL_PATH) ?: '';
            $old = ltrim(str_replace('/storage/', '', $oldPath), '/');
            if ($old !== '') {
                Storage::disk('public')->delete($old);
            }
        }

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

        if ($user->avatar_url && str_contains($user->avatar_url, '/storage/avatars/')) {
            $old = str_replace('/storage/', '', parse_url($user->avatar_url, PHP_URL_PATH) ?? '');
            if ($old !== '') {
                Storage::disk('public')->delete($old);
            }
        }

        $user->delete();

        return response()->json([
            'message' => 'Votre compte a été définitivement supprimé.',
        ]);
    }

    private function payload($user): array
    {
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
