import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kinova_mobile/data/shop_data.dart';
import 'package:kinova_mobile/screens/catalog_screen.dart';
import 'package:kinova_mobile/screens/notifications_screen.dart';
import 'package:kinova_mobile/screens/search_screen.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';
import 'package:kinova_mobile/widgets/animated_logo_badge.dart';
import 'package:kinova_mobile/widgets/motion.dart';
import 'package:kinova_mobile/widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _heroController = PageController();
  final ScrollController _scrollController = ScrollController();
  int _currentHeroIndex = 0;
  bool _showAppbarSearch = false;
  Timer? _heroTimer;

  final List<Map<String, String>> _heroSlides = [
    {
      'title': 'Une sélection\npremium pour vous',
      'tag': 'COLLECTION 2026',
      'subtitle': 'Découvrez les rituels de beauté et pièces d’exception.',
      'image':
          'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=1200&q=80',
      'cta': 'DÉCOUVRIR →',
    },
    {
      'title': 'Savoir-Faire\n& Art de Vivre',
      'tag': 'EDITION LIMITÉE',
      'subtitle': 'Des bougies artisanales et décorations chaleureuses.',
      'image':
          'https://images.unsplash.com/photo-1603006905003-be21c6d3c0d6?w=1200&q=80',
      'cta': 'EXPLORER →',
    },
    {
      'title': 'Cuir & Finitions\nOr Métallique',
      'tag': 'ACCESSOIRES',
      'subtitle': 'L’élégance quotidienne au creux de la main.',
      'image':
          'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=1200&q=80',
      'cta': 'VOIR LA SÉLECTION →',
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      if (_heroController.hasClients && _heroController.position.haveDimensions) {
        final next = (_currentHeroIndex + 1) % _heroSlides.length;
        _heroController.animateToPage(
          next,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset > 60;
    if (shouldShow != _showAppbarSearch) {
      setState(() {
        _showAppbarSearch = shouldShow;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _heroTimer?.cancel();
    _heroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final featured = ShopData.featured;
    final news = ShopData.news;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leadingWidth: 60,
        leading: const Padding(
          padding: EdgeInsets.only(left: 14),
          child: Center(child: AnimatedLogoBadge(size: 38)),
        ),
        title: Text(
          'KINOVA',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        actions: [
          // Bouton Recherche animé au scroll
          AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: _showAppbarSearch ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !_showAppbarSearch,
              child: IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  );
                },
                icon: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: KinovaColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: KinovaColors.gold.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: KinovaColors.brown,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          // Bouton Notification avec Badge non lus
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: KinovaColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: KinovaColors.gold.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: KinovaColors.brown,
                    size: 20,
                  ),
                ),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.all(3.5),
                    decoration: const BoxDecoration(
                      color: KinovaColors.goldRich,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '3',
                      style: TextStyle(
                        color: KinovaColors.brown,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Barre de recherche fictive cliquable
          SliverToBoxAdapter(
            child: FadeSlideIn(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: KinovaColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: KinovaColors.cardShadow,
                      border: Border.all(
                        color: KinovaColors.gold.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: KinovaColors.goldRich,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Rechercher un soin, un sac, une senteur...',
                            style: TextStyle(
                              color: KinovaColors.mutedBrown.withOpacity(0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: KinovaColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: KinovaColors.brown,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Carrousel Hero Promotionnel
          SliverToBoxAdapter(
            child: FadeSlideIn(
              delay: const Duration(milliseconds: 60),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  children: [
                    Container(
                      height: 205,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: KinovaColors.cardShadow,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            PageView.builder(
                              controller: _heroController,
                              onPageChanged: (i) =>
                                  setState(() => _currentHeroIndex = i),
                              itemCount: _heroSlides.length,
                              itemBuilder: (context, index) {
                                final slide = _heroSlides[index];
                                return Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    SoftNetworkImage(url: slide['image']!),
                                    // Layer sombre avec gradient
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomLeft,
                                          end: Alignment.topRight,
                                          colors: [
                                            KinovaColors.brown
                                                .withOpacity(0.82),
                                            KinovaColors.brown
                                                .withOpacity(0.35),
                                            Colors.transparent,
                                          ],
                                          stops: const [0.0, 0.55, 1.0],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 20,
                                      bottom: 22,
                                      right: 20,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: KinovaColors.gold
                                                  .withOpacity(0.9),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              slide['tag']!,
                                              style: const TextStyle(
                                                color: KinovaColors.brown,
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 1.3,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            slide['title']!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall
                                                ?.copyWith(
                                                  color: KinovaColors.cream,
                                                  fontSize: 20,
                                                  height: 1.15,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 10),
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => const CatalogScreen(
                                                    embedded: false,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 7,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withOpacity(0.4),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                slide['cta']!,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 1.2,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            // Indicateurs de page
                            Positioned(
                              right: 18,
                              bottom: 18,
                              child: Row(
                                children: List.generate(
                                  _heroSlides.length,
                                  (idx) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.only(left: 4),
                                    width: _currentHeroIndex == idx ? 18 : 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: _currentHeroIndex == idx
                                          ? KinovaColors.gold
                                          : Colors.white.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // En-tête Catégories
          SliverToBoxAdapter(
            child: FadeSlideIn(
              delay: const Duration(milliseconds: 100),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 26, 18, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nos Univers',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CatalogScreen(embedded: false),
                          ),
                        );
                      },
                      child: const Text(
                        'Tout voir',
                        style: TextStyle(
                          color: KinovaColors.goldRich,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Liste des Catégories en Cartes Stylisées
          SliverToBoxAdapter(
            child: SizedBox(
              height: 125,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                scrollDirection: Axis.horizontal,
                itemCount: ShopData.categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final cat = ShopData.categories[index];
                  final count = ShopData.byCategory(cat.id).length;
                  return FadeSlideIn(
                    delay: Duration(milliseconds: 70 * index),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CatalogScreen(
                              embedded: false,
                              initialCategoryId: cat.id,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 100,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: KinovaColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: KinovaColors.cardShadow,
                          border: Border.all(
                            color: KinovaColors.gold.withOpacity(0.15),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: KinovaColors.gold,
                                    width: 1.5,
                                  ),
                                  boxShadow: KinovaColors.softShadow,
                                ),
                                child: ClipOval(
                                  child: SoftNetworkImage(url: cat.imageUrl),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              cat.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$count pièces',
                              style: TextStyle(
                                fontSize: 9.5,
                                color: KinovaColors.mutedBrown.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // En-tête Sélection Premium
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 28, 18, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sélection Premium',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                  ),
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: KinovaColors.goldRich,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          // Slider Horizontal des Produits Vedettes
          SliverToBoxAdapter(
            child: SizedBox(
              height: 275,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                scrollDirection: Axis.horizontal,
                itemCount: featured.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  return FadeSlideIn(
                    delay: Duration(milliseconds: 60 * index),
                    child: ProductCard(
                      product: featured[index],
                      width: 175,
                      heroTag: 'featured-${featured[index].id}',
                    ),
                  );
                },
              ),
            ),
          ),

          // Section Engagements KINOVA (Garanties / Trust)
          SliverToBoxAdapter(
            child: FadeSlideIn(
              delay: const Duration(milliseconds: 140),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 28, 18, 14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: KinovaColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: KinovaColors.gold.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      _PerkItem(
                        icon: Icons.local_shipping_outlined,
                        title: 'Livraison Offerte',
                        subtitle: 'Dès 75 € d’achat',
                      ),
                      _PerkItem(
                        icon: Icons.eco_outlined,
                        title: 'Soins Naturels',
                        subtitle: 'Formules pures',
                      ),
                      _PerkItem(
                        icon: Icons.verified_user_outlined,
                        title: 'Garantie KINOVA',
                        subtitle: 'Satisfait ou remboursé',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // En-tête Nouveautés
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
              child: Text(
                'Nouveautés & Incontournables',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
              ),
            ),
          ),

          // Grille Nouveautés
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 36),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 14,
                childAspectRatio: 0.65,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => FadeSlideIn(
                  delay: Duration(milliseconds: 50 * index),
                  child: ProductCard(
                    product: news[index],
                    heroTag: 'news-${news[index].id}',
                  ),
                ),
                childCount: news.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PerkItem extends StatelessWidget {
  const _PerkItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: KinovaColors.surface,
            shape: BoxShape.circle,
            boxShadow: KinovaColors.softShadow,
          ),
          child: Icon(icon, color: KinovaColors.brown, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: KinovaColors.brown,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 9,
            color: KinovaColors.mutedBrown,
          ),
        ),
      ],
    );
  }
}

