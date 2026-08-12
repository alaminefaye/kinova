import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kinova_mobile/state/catalog_controller.dart';
import 'package:kinova_mobile/state/favorites_controller.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';
import 'package:kinova_mobile/widgets/motion.dart';
import 'package:kinova_mobile/widgets/product_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fav = context.watch<FavoritesController>();
    final catalog = context.watch<CatalogController>();
    final products = fav.products.isNotEmpty
        ? fav.products
        : catalog.products.where((p) => fav.ids.contains(p.id)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Favoris')),
      body: products.isEmpty
          ? Center(
              child: FadeSlideIn(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.favorite_border,
                      size: 56,
                      color: KinovaColors.sand,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun favori',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Touchez le cœur sur un article',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 14,
                childAspectRatio: 0.65,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) => FadeSlideIn(
                delay: Duration(milliseconds: 40 * index),
                child: ProductCard(
                  product: products[index],
                  heroTag: 'fav-${products[index].id}',
                ),
              ),
            ),
    );
  }
}
