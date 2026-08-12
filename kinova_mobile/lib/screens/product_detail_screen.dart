import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kinova_mobile/models/models.dart';
import 'package:kinova_mobile/state/cart_controller.dart';
import 'package:kinova_mobile/state/favorites_controller.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';
import 'package:kinova_mobile/utils/format.dart';
import 'package:kinova_mobile/widgets/motion.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.product,
    this.heroTag,
  });

  final Product product;
  final String? heroTag;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _qty = 1;
  int _imageIndex = 0;

  Product get product => widget.product;

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesController>();
    final liked = favorites.isFavorite(product.id);
    final gallery = product.gallery;
    final tagToUse = widget.heroTag ?? 'product-${product.id}';

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: MediaQuery.sizeOf(context).height * 0.52,
                pinned: true,
                backgroundColor: KinovaColors.background,
                leading: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                ),
                actions: [
                  IconButton(
                    onPressed: () => favorites.toggle(product),
                    icon: Icon(
                      liked ? Icons.favorite : Icons.favorite_border,
                      color: KinovaColors.brown,
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: tagToUse,
                    child: PageView.builder(
                      itemCount: gallery.length,
                      onPageChanged: (i) => setState(() => _imageIndex = i),
                      itemBuilder: (_, i) => SoftNetworkImage(url: gallery[i]),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (gallery.length > 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              gallery.length,
                              (i) => AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: _imageIndex == i ? 18 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _imageIndex == i
                                      ? KinovaColors.brown
                                      : KinovaColors.sand,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              formatMoney(product.price),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const Spacer(),
                            const Icon(Icons.star, size: 18, color: KinovaColors.gold),
                            const SizedBox(width: 4),
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          product.description,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: KinovaColors.mutedBrown,
                              ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Quantité',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _QtyButton(
                              icon: Icons.remove,
                              onTap: () {
                                if (_qty > 1) setState(() => _qty--);
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                              child: Text(
                                '$_qty',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            _QtyButton(
                              icon: Icons.add,
                              onTap: () => setState(() => _qty++),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: SafeArea(
              child: ElevatedButton(
                onPressed: () {
                  context.read<CartController>().add(product, quantity: _qty);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: KinovaColors.brown,
                      behavior: SnackBarBehavior.floating,
                      content: Text(
                        '${product.name} ajouté au panier',
                        style: const TextStyle(color: KinovaColors.cream),
                      ),
                    ),
                  );
                },
                child: const Text('AJOUTER AU PANIER'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: KinovaColors.sand),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 18, color: KinovaColors.brown),
      ),
    );
  }
}
