import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:kinova_mobile/models/models.dart';
import 'package:kinova_mobile/screens/auth_screen.dart';
import 'package:kinova_mobile/screens/catalog_screen.dart';
import 'package:kinova_mobile/screens/notifications_screen.dart';
import 'package:kinova_mobile/screens/search_screen.dart';
import 'package:kinova_mobile/state/auth_controller.dart';
import 'package:kinova_mobile/state/catalog_controller.dart';
import 'package:kinova_mobile/state/favorites_controller.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';
import 'package:kinova_mobile/widgets/animated_logo_badge.dart';
import 'package:kinova_mobile/widgets/motion.dart';
import 'package:kinova_mobile/widgets/product_card.dart';
import 'package:kinova_mobile/widgets/typewriter_hint.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _heroController = PageController();
  int _currentHeroIndex = 0;
  Timer? _heroTimer;

  @override
  void initState() {
    super.initState();
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final count = context.read<CatalogController>().heroSlides.length;
      if (count <= 1) return;
      if (_heroController.hasClients &&
          _heroController.position.haveDimensions) {
        final next = (_currentHeroIndex + 1) % count;
        _heroController.animateToPage(
          next,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _heroController.dispose();
    super.dispose();
  }

  void _openSearch() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SearchScreen()));
  }

  void _openCatalog({String? categoryId}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            CatalogScreen(embedded: false, initialCategoryId: categoryId),
      ),
    );
  }

  void _onHeroCta(HeroSlide slide) {
    if (slide.linkType == 'none') return;
    if (slide.linkType == 'category' &&
        slide.linkValue != null &&
        slide.linkValue!.isNotEmpty) {
      _openCatalog(categoryId: slide.linkValue);
      return;
    }
    _openCatalog();
  }

  Future<void> _refreshAll() async {
    final catalog = context.read<CatalogController>();
    final auth = context.read<AuthController>();
    final favorites = context.read<FavoritesController>();

    final tasks = <Future<void>>[catalog.load()];

    if (auth.isLoggedIn) {
      tasks.add(auth.refreshProfile());
      tasks.add(favorites.loadFromApi());
    }

    await Future.wait(tasks);
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();
    final auth = context.watch<AuthController>();
    final featured = catalog.featured;
    final news = catalog.news;
    final heroSlides = catalog.heroSlides;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: KinovaColors.background,
        body: Column(
          children: [
            // ===== Zone fixe : header + recherche + slider =====
            Material(
              color: KinovaColors.background,
              elevation: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: KinovaColors.background,
                  boxShadow: [
                    BoxShadow(
                      color: KinovaColors.brown.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _DarkHeader(
                          userName: auth.user?.name,
                          onSearchTap: _openSearch,
                          onBellTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const NotificationsScreen(),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: heroSlides.isEmpty ? 12 : 118),
                      ],
                    ),
                    if (heroSlides.isNotEmpty)
                      Positioned(
                        left: 18,
                        right: 18,
                        bottom: 10,
                        child: SizedBox(
                          height: 200,
                          child: _buildHeroCarousel(context, heroSlides),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ===== Contenu scrollable =====
            Expanded(
              child: RefreshIndicator(
                color: KinovaColors.goldRich,
                backgroundColor: KinovaColors.surface,
                displacement: 36,
                onRefresh: _refreshAll,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    // ===== Bandeau avantages =====
                    SliverToBoxAdapter(
                      child: FadeSlideIn(
                        delay: const Duration(milliseconds: 80),
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: KinovaColors.goldGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.local_shipping_rounded,
                                color: KinovaColors.brown,
                                size: 16,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'LIVRAISON OFFERTE DÈS 50 000 FCFA  •  RETOURS 14 JOURS',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: KinovaColors.brown,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ===== Catégories =====
                    SliverToBoxAdapter(
                      child: FadeSlideIn(
                        delay: const Duration(milliseconds: 110),
                        child: _SectionHeader(
                          title: 'Nos Univers',
                          actionLabel: 'Tout voir',
                          onAction: _openCatalog,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 168,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          scrollDirection: Axis.horizontal,
                          itemCount: catalog.categories.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 13),
                          itemBuilder: (context, index) {
                            final cat = catalog.categories[index];
                            final count = catalog.byCategory(cat.id).length;
                            return FadeSlideIn(
                              delay: Duration(milliseconds: 70 * index),
                              child: _UniverseCard(
                                name: cat.name,
                                imageUrl: cat.imageUrl,
                                count: count,
                                onTap: () => _openCatalog(categoryId: cat.id),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // ===== Sélection Premium =====
                    const SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: 'Sélection Premium',
                        trailingIcon: Icons.auto_awesome_rounded,
                      ),
                    ),
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

                    // ===== Bannière Cercle VIP (si non connecté) =====
                    if (!auth.isLoggedIn)
                      SliverToBoxAdapter(
                        child: FadeSlideIn(
                          delay: const Duration(milliseconds: 140),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
                            child: PressableScale(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const AuthScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  gradient: KinovaColors.darkLuxuryGradient,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: KinovaColors.gold.withOpacity(0.45),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: KinovaColors.brown.withOpacity(
                                        0.30,
                                      ),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: KinovaColors.gold.withOpacity(
                                          0.15,
                                        ),
                                        border: Border.all(
                                          color: KinovaColors.gold.withOpacity(
                                            0.5,
                                          ),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.workspace_premium_rounded,
                                        color: KinovaColors.goldRich,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: const [
                                          Text(
                                            'Rejoignez le Cercle VIP',
                                            style: TextStyle(
                                              fontFamily: 'PlayfairDisplay',
                                              color: Color(0xFFF7E7CE),
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(height: 3),
                                          Text(
                                            '10 000 FCFA dépensés = 1 point. Avantages exclusifs.',
                                            style: TextStyle(
                                              color: KinovaColors.sand,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: KinovaColors.gold,
                                      size: 15,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // ===== Engagements =====
                    SliverToBoxAdapter(
                      child: FadeSlideIn(
                        delay: const Duration(milliseconds: 160),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
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
                                  subtitle: 'Dès 50 000 FCFA d’achat',
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

                    // ===== Nouveautés =====
                    const SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: 'Nouveautés & Incontournables',
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 36),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCarousel(BuildContext context, List<HeroSlide> slides) {
    if (_currentHeroIndex >= slides.length) {
      _currentHeroIndex = 0;
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: KinovaColors.brown.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            PageView.builder(
              controller: _heroController,
              onPageChanged: (i) => setState(() => _currentHeroIndex = i),
              itemCount: slides.length,
              itemBuilder: (context, index) {
                final slide = slides[index];
                return _HeroParallax(
                  controller: _heroController,
                  index: index,
                  fallbackPage: _currentHeroIndex.toDouble(),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      SoftNetworkImage(url: slide.imageUrl),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                            colors: [
                              const Color(0xFF1B110B).withOpacity(0.88),
                              KinovaColors.brown.withOpacity(0.32),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.55, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        bottom: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (slide.tag.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: KinovaColors.gold.withOpacity(0.6),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  slide.tag,
                                  style: const TextStyle(
                                    color: KinovaColors.goldLight,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.6,
                                  ),
                                ),
                              ),
                            if (slide.tag.isNotEmpty)
                              const SizedBox(height: 10),
                            Text(
                              slide.title,
                              style: const TextStyle(
                                fontFamily: 'PlayfairDisplay',
                                color: KinovaColors.cream,
                                fontSize: 22,
                                height: 1.12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (slide.linkType != 'none') ...[
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () => _onHeroCta(slide),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: KinovaColors.goldGradient,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFD4AF37,
                                        ).withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        slide.ctaLabel,
                                        style: const TextStyle(
                                          color: KinovaColors.brown,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.4,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: KinovaColors.brown,
                                        size: 13,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            // Indicateurs
            Positioned(
              right: 18,
              bottom: 18,
              child: Row(
                children: List.generate(
                  slides.length,
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
    );
  }
}

/// Header sombre incurvé : salutation, logo, cloche et recherche.
class _DarkHeader extends StatelessWidget {
  const _DarkHeader({
    required this.userName,
    required this.onSearchTap,
    required this.onBellTap,
  });

  final String? userName;
  final VoidCallback onSearchTap;
  final VoidCallback onBellTap;

  @override
  Widget build(BuildContext context) {
    final firstName = userName?.trim().split(' ').first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 116),
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.6, -1.2),
          radius: 2.2,
          colors: [Color(0xFF3A281C), Color(0xFF2C1E14), Color(0xFF1B110B)],
          stops: [0.0, 0.4, 1.0],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Row(
              children: [
                const AnimatedLogoBadge(size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstName == null
                            ? 'Bienvenue chez'
                            : 'Bonjour $firstName',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          color: KinovaColors.sand,
                          fontSize: 11.5,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 1),
                      const Text(
                        'KINOVA',
                        style: TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          color: Color(0xFFF7E7CE),
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
                ),
                // Cloche notifications style verre
                GestureDetector(
                  onTap: onBellTap,
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: KinovaColors.gold.withOpacity(0.4),
                        width: 0.8,
                      ),
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: KinovaColors.goldLight,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Barre de recherche intégrée au header
            GestureDetector(
              onTap: onSearchTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: KinovaColors.gold.withOpacity(0.35),
                    width: 0.9,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: KinovaColors.gold,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TypewriterHint(
                        phrases: const [
                          'Un soin, un sac, une senteur...',
                          'Rouge, parfum, senteur...',
                          'Mode, beauté, maison...',
                          'Cherchez votre univers...',
                        ],
                        style: TextStyle(
                          color: KinovaColors.sand.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        gradient: KinovaColors.goldGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: KinovaColors.brown,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte « Univers » éditoriale : image pleine, voile sombre, typo luxe.
class _UniverseCard extends StatelessWidget {
  const _UniverseCard({
    required this.name,
    required this.imageUrl,
    required this.count,
    required this.onTap,
  });

  final String name;
  final String imageUrl;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 122,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: KinovaColors.gold.withOpacity(0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: KinovaColors.brown.withOpacity(0.22),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: Stack(
            fit: StackFit.expand,
            children: [
              SoftNetworkImage(url: imageUrl),

              // Voile chocolat pour lisibilité
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF1B110B).withOpacity(0.25),
                      const Color(0xFF1B110B).withOpacity(0.88),
                    ],
                    stops: const [0.35, 0.6, 1.0],
                  ),
                ),
              ),

              // Pastille compteur (fond opaque pour lisibilité sur toute photo)
              Positioned(
                top: 9,
                right: 9,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B110B).withOpacity(0.82),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: KinovaColors.gold.withOpacity(0.75),
                      width: 0.9,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.28),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: KinovaColors.cream,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ),
              ),

              // Nom + trait doré en bas
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 26,
                      height: 2.2,
                      decoration: BoxDecoration(
                        gradient: KinovaColors.goldGradient,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        color: KinovaColors.cream,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: const [
                        Text(
                          'EXPLORER',
                          style: TextStyle(
                            color: KinovaColors.gold,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: KinovaColors.gold,
                          size: 10,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Effet zoom léger sur les pages du carrousel hero (sans décalage horizontal).
class _HeroParallax extends StatelessWidget {
  const _HeroParallax({
    required this.controller,
    required this.index,
    required this.fallbackPage,
    required this.child,
  });

  final PageController controller;
  final int index;
  final double fallbackPage;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        double page = fallbackPage;
        if (controller.hasClients && controller.position.haveDimensions) {
          page = controller.page ?? fallbackPage;
        }
        final delta = (page - index).clamp(-1.0, 1.0);
        // Zoom très doux — pas de translate (évite le décalage / bords moches)
        final scale = 1.0 - delta.abs() * 0.035;
        final opacity = (1.0 - delta.abs() * 0.25).clamp(0.75, 1.0);
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.center,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// En-tête de section avec accent doré signature.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
    this.trailingIcon,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 14),
      child: Row(
        children: [
          Container(
            width: 3.5,
            height: 20,
            decoration: BoxDecoration(
              gradient: KinovaColors.goldGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (trailingIcon != null)
            Icon(trailingIcon, color: KinovaColors.goldRich, size: 18),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Row(
                children: [
                  Text(
                    actionLabel!,
                    style: const TextStyle(
                      color: KinovaColors.goldRich,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: KinovaColors.goldRich,
                    size: 17,
                  ),
                ],
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
          style: const TextStyle(fontSize: 9, color: KinovaColors.mutedBrown),
        ),
      ],
    );
  }
}
