import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kinova_mobile/screens/cart_screen.dart';
import 'package:kinova_mobile/screens/catalog_screen.dart';
import 'package:kinova_mobile/screens/favorites_screen.dart';
import 'package:kinova_mobile/screens/home_screen.dart';
import 'package:kinova_mobile/screens/profile_screen.dart';
import 'package:kinova_mobile/state/cart_controller.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';
import 'package:kinova_mobile/widgets/cart_fly.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index;

  // Le panier occupe la place centrale (bouton mis en avant).
  final _pages = const [
    HomeScreen(),
    CatalogScreen(),
    CartScreen(),
    FavoritesScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartController>().itemCount;

    return Scaffold(
      extendBody: false,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.015),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(_index),
          child: _pages[_index],
        ),
      ),
      bottomNavigationBar: _KinovaNavBar(
        index: _index,
        cartCount: cartCount,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _KinovaNavBar extends StatelessWidget {
  const _KinovaNavBar({
    required this.index,
    required this.cartCount,
    required this.onChanged,
  });

  final int index;
  final int cartCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KinovaColors.surface,
        boxShadow: [
          BoxShadow(
            color: KinovaColors.brown.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, -6),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: KinovaColors.gold.withValues(alpha: 0.22),
            width: 0.8,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Accueil',
                active: index == 0,
                onTap: () => onChanged(0),
              ),
              _NavItem(
                icon: Icons.grid_view_outlined,
                activeIcon: Icons.grid_view_rounded,
                label: 'Boutique',
                active: index == 1,
                onTap: () => onChanged(1),
              ),
              Expanded(
                child: _CartNavButton(
                  active: index == 2,
                  count: cartCount,
                  onTap: () => onChanged(2),
                ),
              ),
              _NavItem(
                icon: Icons.favorite_border_rounded,
                activeIcon: Icons.favorite_rounded,
                label: 'Favoris',
                active: index == 3,
                onTap: () => onChanged(3),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Compte',
                active: index == 4,
                onTap: () => onChanged(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pastille animée derrière l'icône active
            AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: active ? 18 : 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                gradient: active ? KinovaColors.darkLuxuryGradient : null,
                borderRadius: BorderRadius.circular(18),
                border: active
                    ? Border.all(
                        color: KinovaColors.gold.withValues(alpha: 0.5),
                        width: 1,
                      )
                    : null,
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: KinovaColors.brown.withValues(alpha: 0.30),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  active ? activeIcon : icon,
                  key: ValueKey(active),
                  size: 21,
                  color: active
                      ? KinovaColors.goldLight
                      : KinovaColors.mutedBrown,
                ),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 9.5,
                letterSpacing: 0.4,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? KinovaColors.brown : KinovaColors.mutedBrown,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton panier central mis en avant : cercle doré surélevé qui déborde
/// au-dessus de la barre, avec rebond quand un article y atterrit.
class _CartNavButton extends StatefulWidget {
  const _CartNavButton({
    required this.active,
    required this.count,
    required this.onTap,
  });

  final bool active;
  final int count;
  final VoidCallback onTap;

  @override
  State<_CartNavButton> createState() => _CartNavButtonState();
}

class _CartNavButtonState extends State<_CartNavButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    CartFly.bumps.addListener(_onBump);
  }

  void _onBump() {
    _bounce.forward(from: 0);
  }

  @override
  void dispose() {
    CartFly.bumps.removeListener(_onBump);
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: SizedBox(
        height: 68,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // Cercle doré qui déborde au-dessus de la barre
            Positioned(
              top: -20,
              child: AnimatedBuilder(
                animation: _bounce,
                builder: (context, child) {
                  final t = Curves.elasticOut.transform(_bounce.value);
                  final scale = _bounce.isAnimating || _bounce.value > 0
                      ? 1.0 + 0.18 * (1 - t)
                      : 1.0;
                  return Transform.scale(scale: scale, child: child);
                },
                child: AnimatedContainer(
                  key: CartFly.cartKey,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: widget.active
                        ? KinovaColors.darkLuxuryGradient
                        : KinovaColors.goldGradient,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.active
                          ? KinovaColors.goldRich
                          : KinovaColors.cream,
                      width: 2.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: KinovaColors.goldRich.withValues(alpha: 0.45),
                        blurRadius: 16,
                        spreadRadius: 1,
                        offset: const Offset(0, 5),
                      ),
                      BoxShadow(
                        color: KinovaColors.brown.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_rounded,
                        size: 24,
                        color: widget.active
                            ? KinovaColors.goldLight
                            : KinovaColors.brown,
                      ),
                      if (widget.count > 0)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5.5,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: KinovaColors.brown,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: KinovaColors.goldRich,
                                width: 1.2,
                              ),
                            ),
                            child: Text(
                              '${widget.count}',
                              style: const TextStyle(
                                color: KinovaColors.goldLight,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Libellé sous le cercle
            Positioned(
              bottom: 6,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 9.5,
                  letterSpacing: 0.4,
                  fontWeight:
                      widget.active ? FontWeight.w700 : FontWeight.w500,
                  color: widget.active
                      ? KinovaColors.brown
                      : KinovaColors.mutedBrown,
                ),
                child: const Text('Panier'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
