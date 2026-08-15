import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kinova_mobile/models/models.dart';
import 'package:kinova_mobile/screens/product_detail_screen.dart';
import 'package:kinova_mobile/state/cart_controller.dart';
import 'package:kinova_mobile/state/favorites_controller.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';
import 'package:kinova_mobile/utils/format.dart';
import 'package:kinova_mobile/widgets/cart_fly.dart';
import 'package:kinova_mobile/widgets/motion.dart';
import 'package:kinova_mobile/widgets/promo_badge.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.width,
    this.heroTag,
  });

  final Product product;
  final double? width;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesController>();
    final liked = favorites.isFavorite(product.id);
    final cart = context.read<CartController>();
    final tagToUse = heroTag ?? 'product-${product.id}';

    return PressableScale(
      child: Container(
      width: width,
      decoration: BoxDecoration(
        color: KinovaColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: KinovaColors.cardShadow,
        border: Border.all(
          color: KinovaColors.gold.withOpacity(0.16),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(
                  product: product,
                  heroTag: tagToUse,
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Visuel Produit & Badges
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: tagToUse,
                      child: SoftNetworkImage(url: product.imageUrl),
                    ),

                    // Gradient overlay bas de l'image
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.05),
                              Colors.black.withOpacity(0.25),
                            ],
                            stops: const [0.5, 0.8, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Badge ÉPUISÉ / PROMO / NOUVEAU / BESTSELLER
                    if (product.isOutOfStock)
                      Positioned(
                        left: 10,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF64748B),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'ÉPUISÉ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      )
                    else if (product.hasPromo)
                      Positioned(
                        left: 10,
                        top: 10,
                        child: AnimatedPromoBadge(
                          discountPercent: product.discountPercent,
                        ),
                      )
                    else if (product.isNew || product.isFeatured)
                      Positioned(
                        left: 10,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4.5,
                          ),
                          decoration: BoxDecoration(
                            gradient: product.isNew
                                ? KinovaColors.goldGradient
                                : KinovaColors.darkLuxuryGradient,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            product.isNew ? 'NOUVEAU' : 'BESTSELLER',
                            style: const TextStyle(
                              color: KinovaColors.cream,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ),

                    // Badge de Note étoiles en bas à gauche de l'image
                    Positioned(
                      left: 10,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: Color(0xFFFFD700),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              product.ratingsCount > 0
                                   ? product.rating.toStringAsFixed(1)
                                   : '—',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bouton Favoris Flottant
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => favorites.toggle(product),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: KinovaColors.surface.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: KinovaColors.softShadow,
                              border: Border.all(
                                color: KinovaColors.gold.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              transitionBuilder: (child, anim) => ScaleTransition(
                                scale: anim,
                                child: child,
                              ),
                              child: Icon(
                                liked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                key: ValueKey(liked),
                                color: liked
                                    ? const Color(0xFFE53935)
                                    : KinovaColors.brown,
                                size: 17,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Info Produit & Action
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: KinovaColors.brown,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (product.hasPromo)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                formatMoney(product.price),
                                style: const TextStyle(
                                  color: Color(0xFF9E8E82),
                                  fontSize: 11,
                                  decoration: TextDecoration.lineThrough,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                formatMoney(product.promoPrice!),
                                style: const TextStyle(
                                  color: Color(0xFFB71C1C),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            formatMoney(product.price),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: KinovaColors.brown,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                          ),
                        // Bouton d'ajout rapide au panier (+) ou désactivé si épuisé
                        GestureDetector(
                          onTap: product.isOutOfStock
                              ? null
                              : () {
                                  cart.add(product);
                                  // Le produit s'envole vers le panier
                                  CartFly.fly(context, product.imageUrl);
                                },
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: product.isOutOfStock
                                  ? const Color(0xFFE2E8F0)
                                  : KinovaColors.brown,
                              shape: BoxShape.circle,
                              boxShadow: product.isOutOfStock
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: KinovaColors.brown.withOpacity(0.25),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Icon(
                              product.isOutOfStock
                                  ? Icons.remove_rounded
                                  : Icons.add_rounded,
                              color: product.isOutOfStock
                                  ? const Color(0xFF94A3B8)
                                  : KinovaColors.cream,
                              size: product.isOutOfStock ? 15 : 19,
                            ),
                          ),
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
      ),
    );
  }
}

