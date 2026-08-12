import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kinova_mobile/screens/cart_screen.dart';
import 'package:kinova_mobile/screens/catalog_screen.dart';
import 'package:kinova_mobile/screens/favorites_screen.dart';
import 'package:kinova_mobile/screens/home_screen.dart';
import 'package:kinova_mobile/screens/profile_screen.dart';
import 'package:kinova_mobile/state/cart_controller.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index;

  final _pages = const [
    HomeScreen(),
    CatalogScreen(),
    FavoritesScreen(),
    CartScreen(),
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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: KeyedSubtree(
          key: ValueKey(_index),
          child: _pages[_index],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: KinovaColors.surface,
          boxShadow: [
            BoxShadow(
              color: KinovaColors.brown.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: KinovaColors.gold.withOpacity(0.2),
              width: 0.8,
            ),
          ),
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Accueil',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.grid_view_outlined),
                activeIcon: Icon(Icons.grid_view),
                label: 'Boutique',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.favorite_border),
                activeIcon: Icon(Icons.favorite),
                label: 'Favoris',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: cartCount > 0,
                  backgroundColor: KinovaColors.brown,
                  label: Text('$cartCount'),
                  child: const Icon(Icons.shopping_bag_outlined),
                ),
                activeIcon: Badge(
                  isLabelVisible: cartCount > 0,
                  backgroundColor: KinovaColors.brown,
                  label: Text('$cartCount'),
                  child: const Icon(Icons.shopping_bag),
                ),
                label: 'Panier',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Compte',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
