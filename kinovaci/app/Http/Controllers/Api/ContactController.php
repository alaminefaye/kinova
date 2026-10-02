<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ContactMessage;
use App\Services\AppSettings;
use Illuminate\Http\Request;

class ContactController extends Controller
{
    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'email' => ['required', 'email', 'max:160'],
            'phone' => ['nullable', 'string', 'max:40'],
            'subject' => ['required', 'string', 'max:160'],
            'message' => ['required', 'string', 'max:5000'],
        ]);

        $message = ContactMessage::query()->create([
            ...$data,
            'user_id' => $request->user()?->id ?? auth('sanctum')->id(),
            'status' => 'new',
        ]);

        return response()->json([
            'message' => 'Message envoyé. Nous vous répondrons rapidement.',
            'data' => $message,
        ], 201);
    }

    public function help()
    {
        return response()->json([
            'data' => [
                'email' => config('kinova.support_email'),
                'phone' => config('kinova.support_phone'),
                'whatsapp' => config('kinova.support_whatsapp'),
                'hours' => config('kinova.support_hours'),
                'privacy_url' => url(config('kinova.privacy_url')),
                'support_url' => url(config('kinova.support_url')),
                'faqs' => array_values(array_filter([
                    [
                        'q' => 'Quels sont les délais de livraison ?',
                        'a' => '2 à 5 jours ouvrés selon votre ville.',
                    ],
                    [
                        'q' => 'Comment suivre ma commande ?',
                        'a' => 'Utilisez la référence KV-… ou consultez Mes commandes si vous êtes connecté.',
                    ],
                    ! AppSettings::loyaltyEnabled() ? null : [
                        'q' => 'Comment fonctionnent les points VIP ?',
                        'a' => AppSettings::render('{montant} dépensés = {points}.').' Les paliers débloquent Silver, Gold puis VIP avec des remises et privilèges exclusifs.',
                    ],
                    [
                        'q' => 'Puis-je retourner un article ?',
                        'a' => 'Oui, sous 14 jours si l’article est non utilisé, dans son emballage.',
                    ],
                ])),
            ],
        ]);
    }
}
