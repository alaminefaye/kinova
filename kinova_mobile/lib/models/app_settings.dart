/// Paramètres boutique pilotés depuis le dashboard (`GET /api/settings`).
class AppSettings {
  const AppSettings({
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
    this.promoBannerText =
        'LIVRAISON OFFERTE DÈS 50 000 FCFA  •  RETOURS 14 JOURS',
    this.vipTitle = 'Rejoignez le Cercle VIP',
    this.vipSubtitle = '10 000 FCFA dépensés = 1 point. Avantages exclusifs.',
    this.perks = const [
      PerkText('Livraison Offerte', 'Dès 50 000 FCFA d’achat'),
      PerkText('Soins Naturels', 'Formules pures'),
      PerkText('Garantie KINOVA', 'Satisfait ou remboursé'),
    ],
    this.categoriesTitle = 'Nos Univers',
    this.featuredTitle = 'Sélection Premium',
    this.newsTitle = 'Nouveautés & Incontournables',
  });

  final double shippingFee;
  final bool freeShippingEnabled;
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
    if (!isDelivery) return 0;
    if (freeShippingEnabled && subtotal >= freeShippingThreshold) return 0;
    return shippingFee;
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    const d = AppSettings();
    final shipping = _map(json['shipping']);
    final loyalty = _map(json['loyalty']);
    final sections = _map(json['sections']);
    final texts = _map(json['texts']);

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
