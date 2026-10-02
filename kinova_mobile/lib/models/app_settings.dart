/// Paramètres boutique pilotés depuis le dashboard (`GET /api/settings`).
class AppSettings {
  const AppSettings({
    this.shippingMode = 'courier',
    this.shippingNote =
        'Livraison optionnelle. Les frais sont à régler directement au livreur selon votre zone.',
    this.shippingFee = 2500,
    this.freeShippingEnabled = true,
    this.freeShippingThreshold = 50000,
    this.loyaltyAmountPerStep = 10000,
    this.loyaltyPointsPerStep = 1,
    this.showHero = true,
    this.showPromoBanner = true,
    this.showCategories = true,
    this.showFeatured = true,
    this.showVipBanner = true,
    this.showPerks = true,
    this.showNews = true,
    this.promoBannerText = 'PAIEMENT À LA LIVRAISON  •  RETOURS 14 JOURS',
    this.vipTitle = 'Rejoignez le Cercle VIP',
    this.vipSubtitle = '10 000 FCFA dépensés = 1 point. Avantages exclusifs.',
    this.perks = const [
      PerkText('Livraison à domicile', 'Paiement à la réception'),
      PerkText('Soins Naturels', 'Formules pures'),
      PerkText('Garantie KINOVA', 'Satisfait ou remboursé'),
    ],
    this.categoriesTitle = 'Nos Univers',
    this.featuredTitle = 'Sélection Premium',
    this.newsTitle = 'Nouveautés & Incontournables',
    this.tierSilverPoints = 20,
    this.tierGoldPoints = 50,
    this.tierVipPoints = 100,
    this.profileShowLoyalty = true,
    this.profileShowTierBadge = true,
    this.profileShowNextTier = true,
    this.profileLoyaltyTitle = 'FIDÉLITÉ KINOVA',
    this.profileLoyaltyRule = '10 000 FCFA dépensés = 1 point',
    this.invoiceFooter = 'KINOVA — Abidjan · kinovaci.com',
    this.invoiceStampUrl,
    this.invoiceStampLabel = 'Cachet & signature',
  });

  final int tierSilverPoints;
  final int tierGoldPoints;
  final int tierVipPoints;

  final bool profileShowLoyalty;
  final bool profileShowTierBadge;
  final bool profileShowNextTier;
  final String profileLoyaltyTitle;
  final String profileLoyaltyRule;

  /// Facture : pied de page (multi-lignes), cachet affiché sous le total.
  final String invoiceFooter;
  final String? invoiceStampUrl;
  final String invoiceStampLabel;

  /// « Plus que X points pour OR », ou null si le palier max est atteint.
  String? nextTierHint(int points) {
    final steps = [
      (tierSilverPoints, 'ARGENT'),
      (tierGoldPoints, 'OR'),
      (tierVipPoints, 'VIP'),
    ];
    for (final (threshold, label) in steps) {
      if (points < threshold) {
        final missing = threshold - points;
        return 'Plus que $missing point${missing > 1 ? 's' : ''} pour $label';
      }
    }
    return null;
  }

  /// courier : frais réglés au livreur (non facturés) ; fixed : frais fixes.
  final String shippingMode;
  final String shippingNote;
  final double shippingFee;
  final bool freeShippingEnabled;

  bool get shippingPaidToCourier => shippingMode != 'fixed';
  final double freeShippingThreshold;
  final double loyaltyAmountPerStep;
  final int loyaltyPointsPerStep;

  final bool showHero;
  final bool showPromoBanner;
  final bool showCategories;
  final bool showFeatured;
  final bool showVipBanner;
  final bool showPerks;
  final bool showNews;

  final String promoBannerText;
  final String vipTitle;
  final String vipSubtitle;
  final List<PerkText> perks;
  final String categoriesTitle;
  final String featuredTitle;
  final String newsTitle;

  double shippingFor(double subtotal, {bool isDelivery = true}) {
    if (!isDelivery || shippingPaidToCourier) return 0;
    if (freeShippingEnabled && subtotal >= freeShippingThreshold) return 0;
    return shippingFee;
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    const d = AppSettings();
    final shipping = _map(json['shipping']);
    final loyalty = _map(json['loyalty']);
    final sections = _map(json['sections']);
    final texts = _map(json['texts']);
    final profile = _map(json['profile']);
    final tiers = _map(loyalty['tiers']);
    final invoice = _map(json['invoice']);
    final stampUrl = invoice['stamp_url']?.toString();

    final perksRaw = texts['perks'];
    final perks = perksRaw is List
        ? perksRaw
              .whereType<Map>()
              .map(
                (p) => PerkText(
                  (p['title'] ?? '').toString(),
                  (p['subtitle'] ?? '').toString(),
                ),
              )
              .toList()
        : d.perks;

    return AppSettings(
      shippingMode: _str(shipping['mode'], d.shippingMode),
      shippingNote: _str(shipping['note'], d.shippingNote),
      shippingFee: _num(shipping['fee'], d.shippingFee),
      freeShippingEnabled: _bool(
        shipping['free_enabled'],
        d.freeShippingEnabled,
      ),
      freeShippingThreshold: _num(
        shipping['free_threshold'],
        d.freeShippingThreshold,
      ),
      loyaltyAmountPerStep: _num(
        loyalty['amount_per_step'],
        d.loyaltyAmountPerStep,
      ),
      loyaltyPointsPerStep: _num(
        loyalty['points_per_step'],
        d.loyaltyPointsPerStep.toDouble(),
      ).toInt(),
      showHero: _bool(sections['hero'], d.showHero),
      showPromoBanner: _bool(sections['promo_banner'], d.showPromoBanner),
      showCategories: _bool(sections['categories'], d.showCategories),
      showFeatured: _bool(sections['featured'], d.showFeatured),
      showVipBanner: _bool(sections['vip_banner'], d.showVipBanner),
      showPerks: _bool(sections['perks'], d.showPerks),
      showNews: _bool(sections['news'], d.showNews),
      promoBannerText: _str(texts['promo_banner'], d.promoBannerText),
      vipTitle: _str(texts['vip_title'], d.vipTitle),
      vipSubtitle: _str(texts['vip_subtitle'], d.vipSubtitle),
      perks: perks,
      categoriesTitle: _str(texts['categories_title'], d.categoriesTitle),
      featuredTitle: _str(texts['featured_title'], d.featuredTitle),
      newsTitle: _str(texts['news_title'], d.newsTitle),
      tierSilverPoints: _num(
        tiers['silver'],
        d.tierSilverPoints.toDouble(),
      ).toInt(),
      tierGoldPoints: _num(tiers['gold'], d.tierGoldPoints.toDouble()).toInt(),
      tierVipPoints: _num(tiers['vip'], d.tierVipPoints.toDouble()).toInt(),
      profileShowLoyalty: _bool(profile['show_loyalty'], d.profileShowLoyalty),
      profileShowTierBadge: _bool(
        profile['show_tier_badge'],
        d.profileShowTierBadge,
      ),
      profileShowNextTier: _bool(
        profile['show_next_tier'],
        d.profileShowNextTier,
      ),
      profileLoyaltyTitle: _str(
        profile['loyalty_title'],
        d.profileLoyaltyTitle,
      ),
      profileLoyaltyRule: _str(profile['loyalty_rule'], d.profileLoyaltyRule),
      invoiceFooter: _str(invoice['footer'], d.invoiceFooter),
      invoiceStampUrl: (stampUrl == null || stampUrl.isEmpty) ? null : stampUrl,
      invoiceStampLabel: _str(invoice['stamp_label'], d.invoiceStampLabel),
    );
  }

  static Map<String, dynamic> _map(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : const {};

  static double _num(dynamic v, double fallback) =>
      v == null ? fallback : (double.tryParse('$v') ?? fallback);

  static bool _bool(dynamic v, bool fallback) {
    if (v is bool) return v;
    if (v == null) return fallback;
    return v == 1 || v == '1' || v == 'true';
  }

  static String _str(dynamic v, String fallback) =>
      v == null ? fallback : v.toString();
}

class PerkText {
  const PerkText(this.title, this.subtitle);

  final String title;
  final String subtitle;
}
