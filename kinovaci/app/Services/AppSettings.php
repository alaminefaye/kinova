<?php

namespace App\Services;

use App\Models\Setting;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Storage;

class AppSettings
{
    private const CACHE_KEY = 'kinova_app_settings';

    /**
     * Valeurs par défaut. Placeholders utilisables dans les textes :
     * {seuil} seuil livraison offerte, {frais} frais de livraison,
     * {montant} montant pour gagner des points, {points} points gagnés (« 1 point », « 2 points »).
     */
    public const DEFAULTS = [
        // Livraison
        // courier : frais non fixés par la boutique, réglés directement au livreur
        // fixed   : frais fixes ajoutés à la commande
        'shipping_mode' => 'courier',
        'shipping_note' => 'Livraison optionnelle. Les frais sont à régler directement au livreur selon votre zone.',
        'shipping_fee' => 2500,
        'free_shipping_enabled' => true,
        'free_shipping_threshold' => 50000,

        // Fidélité
        'loyalty_amount_per_step' => 10000,
        'loyalty_points_per_step' => 1,
        'tier_silver_points' => 20,
        'tier_gold_points' => 50,
        'tier_vip_points' => 100,

        // Sections accueil (affichées / masquées)
        'section_hero' => true,
        'section_promo_banner' => true,
        'section_categories' => true,
        'section_featured' => true,
        'section_vip_banner' => true,
        'section_perks' => true,
        'section_news' => true,

        // Textes accueil
        'promo_banner_text' => 'PAIEMENT À LA LIVRAISON  •  RETOURS 14 JOURS',
        'vip_title' => 'Rejoignez le Cercle VIP',
        'vip_subtitle' => '{montant} dépensés = {points}. Avantages exclusifs.',
        'perk1_title' => 'Livraison à domicile',
        'perk1_subtitle' => 'Paiement à la réception',
        'perk2_title' => 'Soins Naturels',
        'perk2_subtitle' => 'Formules pures',
        'perk3_title' => 'Garantie KINOVA',
        'perk3_subtitle' => 'Satisfait ou remboursé',
        'categories_title' => 'Nos Univers',
        'featured_title' => 'Sélection Premium',
        'news_title' => 'Nouveautés & Incontournables',

        // Profil client (carte fidélité)
        'profile_show_loyalty' => true,
        'profile_show_tier_badge' => true,
        'profile_show_next_tier' => true,
        'profile_loyalty_title' => 'FIDÉLITÉ KINOVA',
        'profile_loyalty_rule' => '{montant} dépensés = {points}',

        // Facture (web + PDF de l'app)
        'invoice_footer' => 'KINOVA — Abidjan · kinovaci.com',
        'invoice_stamp_path' => '',
        'invoice_stamp_label' => 'Cachet & signature',
    ];

    public const INVOICE_STAMP_DIR = 'invoice';

    public const INTEGER_KEYS = [
        'shipping_fee',
        'free_shipping_threshold',
        'loyalty_amount_per_step',
        'loyalty_points_per_step',
        'tier_silver_points',
        'tier_gold_points',
        'tier_vip_points',
    ];

    public static function all(): array
    {
        $stored = Cache::rememberForever(self::CACHE_KEY, function () {
            return Setting::query()->pluck('value', 'key')->all();
        });

        $values = self::DEFAULTS;
        foreach ($stored as $key => $value) {
            if (array_key_exists($key, self::DEFAULTS) && $value !== null) {
                $values[$key] = $value;
            }
        }

        return self::normalize($values);
    }

    public static function get(string $key): mixed
    {
        return self::all()[$key] ?? self::DEFAULTS[$key] ?? null;
    }

    public static function update(array $values): array
    {
        foreach ($values as $key => $value) {
            if (! array_key_exists($key, self::DEFAULTS)) {
                continue;
            }
            Setting::query()->updateOrCreate(['key' => $key], ['value' => $value]);
        }

        Cache::forget(self::CACHE_KEY);

        return self::all();
    }

    public static function shippingFor(float $subtotal, bool $isDelivery = true): float
    {
        if (! $isDelivery) {
            return 0.0;
        }

        $s = self::all();
        if ($s['shipping_mode'] !== 'fixed') {
            return 0.0;
        }
        if ($s['free_shipping_enabled'] && $subtotal >= $s['free_shipping_threshold']) {
            return 0.0;
        }

        return (float) $s['shipping_fee'];
    }

    public static function pointsForAmount(float $amount): int
    {
        $s = self::all();
        $step = max(1, $s['loyalty_amount_per_step']);

        return (int) floor($amount / $step) * $s['loyalty_points_per_step'];
    }

    public static function formatMoney(int|float $amount): string
    {
        return number_format((float) $amount, 0, ',', ' ').' FCFA';
    }

    public static function render(string $text, ?array $settings = null): string
    {
        $s = $settings ?? self::all();

        return strtr($text, [
            '{seuil}' => self::formatMoney($s['free_shipping_threshold']),
            '{frais}' => self::formatMoney($s['shipping_fee']),
            '{montant}' => self::formatMoney($s['loyalty_amount_per_step']),
            '{points}' => $s['loyalty_points_per_step'].' point'.($s['loyalty_points_per_step'] > 1 ? 's' : ''),
        ]);
    }

    public static function invoicePayload(?array $settings = null): array
    {
        $s = $settings ?? self::all();
        $path = $s['invoice_stamp_path'];

        return [
            'footer' => trim($s['invoice_footer']),
            'stamp_url' => $path !== '' && Storage::disk('public')->exists($path)
                ? Storage::disk('public')->url($path)
                : null,
            'stamp_label' => trim($s['invoice_stamp_label']),
        ];
    }

    /**
     * Payload consommé par l'app mobile et la boutique web.
     */
    public static function publicPayload(): array
    {
        $s = self::all();

        return [
            'shipping' => [
                'mode' => $s['shipping_mode'],
                'note' => self::render($s['shipping_note'], $s),
                'fee' => $s['shipping_fee'],
                'free_enabled' => $s['free_shipping_enabled'],
                'free_threshold' => $s['free_shipping_threshold'],
            ],
            'loyalty' => [
                'amount_per_step' => $s['loyalty_amount_per_step'],
                'points_per_step' => $s['loyalty_points_per_step'],
                'tiers' => [
                    'silver' => $s['tier_silver_points'],
                    'gold' => $s['tier_gold_points'],
                    'vip' => $s['tier_vip_points'],
                ],
            ],
            'sections' => [
                'hero' => $s['section_hero'],
                'promo_banner' => $s['section_promo_banner'],
                'categories' => $s['section_categories'],
                'featured' => $s['section_featured'],
                'vip_banner' => $s['section_vip_banner'],
                'perks' => $s['section_perks'],
                'news' => $s['section_news'],
            ],
            'texts' => [
                'promo_banner' => self::render($s['promo_banner_text'], $s),
                'vip_title' => self::render($s['vip_title'], $s),
                'vip_subtitle' => self::render($s['vip_subtitle'], $s),
                'perks' => [
                    ['title' => self::render($s['perk1_title'], $s), 'subtitle' => self::render($s['perk1_subtitle'], $s)],
                    ['title' => self::render($s['perk2_title'], $s), 'subtitle' => self::render($s['perk2_subtitle'], $s)],
                    ['title' => self::render($s['perk3_title'], $s), 'subtitle' => self::render($s['perk3_subtitle'], $s)],
                ],
                'categories_title' => self::render($s['categories_title'], $s),
                'featured_title' => self::render($s['featured_title'], $s),
                'news_title' => self::render($s['news_title'], $s),
            ],
            'profile' => [
                'show_loyalty' => $s['profile_show_loyalty'],
                'show_tier_badge' => $s['profile_show_tier_badge'],
                'show_next_tier' => $s['profile_show_next_tier'],
                'loyalty_title' => self::render($s['profile_loyalty_title'], $s),
                'loyalty_rule' => self::render($s['profile_loyalty_rule'], $s),
            ],
            'invoice' => self::invoicePayload($s),
        ];
    }

    private static function normalize(array $values): array
    {
        foreach ($values as $key => $value) {
            $default = self::DEFAULTS[$key];
            if (in_array($key, self::INTEGER_KEYS, true)) {
                $values[$key] = (int) $value;
            } elseif (is_bool($default)) {
                $values[$key] = filter_var($value, FILTER_VALIDATE_BOOLEAN);
            } else {
                $values[$key] = (string) $value;
            }
        }

        return $values;
    }
}
