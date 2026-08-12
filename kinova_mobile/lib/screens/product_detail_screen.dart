import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kinova_mobile/api/api_client.dart';
import 'package:kinova_mobile/api/api_exception.dart';
import 'package:kinova_mobile/models/models.dart';
import 'package:kinova_mobile/screens/auth_screen.dart';
import 'package:kinova_mobile/state/auth_controller.dart';
import 'package:kinova_mobile/state/cart_controller.dart';
import 'package:kinova_mobile/state/catalog_controller.dart';
import 'package:kinova_mobile/state/favorites_controller.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';
import 'package:kinova_mobile/utils/format.dart';
import 'package:kinova_mobile/widgets/cart_fly.dart';
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
  late double _average;
  late int _ratingsCount;
  int? _myRating;
  bool _ratingLoading = false;

  @override
  void initState() {
    super.initState();
    _average = widget.product.rating;
    _ratingsCount = widget.product.ratingsCount;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMyRating());
  }

  Product get _baseProduct => widget.product;

  Future<void> _loadMyRating() async {
    final auth = context.read<AuthController>();
    final api = context.read<ApiClient>();
    try {
      final path = auth.isLoggedIn
          ? '/customer/products/${widget.product.id}/rating'
          : '/products/${widget.product.id}/rating';
      final res = await api.get(path);
      final data = res is Map && res['data'] is Map
          ? Map<String, dynamic>.from(res['data'] as Map)
          : <String, dynamic>{};
      if (!mounted) return;
      setState(() {
        _average = double.tryParse('${data['average']}') ?? _average;
        _ratingsCount = int.tryParse('${data['count']}') ?? _ratingsCount;
        final mine = data['my_rating'];
        _myRating = mine == null ? null : int.tryParse('$mine');
      });
      context.read<CatalogController>().patchProductRating(
            widget.product.id,
            _average,
            _ratingsCount,
          );
    } catch (_) {
      // garde les valeurs locales
    }
  }

  Future<void> _rate(int stars) async {
    final auth = context.read<AuthController>();
    if (!auth.isLoggedIn) {
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
      if (ok != true || !mounted) return;
    }

    setState(() {
      _ratingLoading = true;
      _myRating = stars;
    });

    try {
      final res = await context.read<ApiClient>().post('/customer/ratings', body: {
        'product_id': int.tryParse(widget.product.id) ?? widget.product.id,
        'stars': stars,
      });
      final data = res is Map && res['data'] is Map
          ? Map<String, dynamic>.from(res['data'] as Map)
          : <String, dynamic>{};
      if (!mounted) return;
      final avg = double.tryParse('${data['average']}') ?? _average;
      final count = int.tryParse('${data['count']}') ?? _ratingsCount;
      setState(() {
        _average = avg;
        _ratingsCount = count;
        _myRating = int.tryParse('${data['my_rating']}') ?? stars;
      });
      context.read<CatalogController>().patchProductRating(
            widget.product.id,
            avg,
            count,
          );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Merci pour votre note !'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d’enregistrer la note')),
      );
    } finally {
      if (mounted) setState(() => _ratingLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = context.watch<CatalogController>().byId(widget.product.id) ??
        _baseProduct;
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
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
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
                        Text(
                          formatMoney(product.price),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 18),

                        // ===== Notation dynamique =====
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          decoration: BoxDecoration(
                            color: KinovaColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: KinovaColors.gold.withOpacity(0.22),
                            ),
                            boxShadow: KinovaColors.softShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: KinovaColors.goldRich,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _ratingsCount > 0
                                        ? _average.toStringAsFixed(1)
                                        : '—',
                                    style: const TextStyle(
                                      fontFamily: 'PlayfairDisplay',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: KinovaColors.brown,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _ratingsCount == 0
                                        ? 'Aucune note'
                                        : '$_ratingsCount avis',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: KinovaColors.mutedBrown
                                          .withOpacity(0.95),
                                    ),
                                  ),
                                  if (_ratingLoading) ...[
                                    const Spacer(),
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: KinovaColors.gold,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _myRating == null
                                    ? 'Notez cet article'
                                    : 'Votre note : $_myRating/5',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: KinovaColors.mutedBrown,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: List.generate(5, (index) {
                                  final star = index + 1;
                                  final filled = (_myRating ?? 0) >= star;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: GestureDetector(
                                      onTap: _ratingLoading
                                          ? null
                                          : () => _rate(star),
                                      child: AnimatedScale(
                                        scale: filled ? 1.08 : 1.0,
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        child: Icon(
                                          filled
                                              ? Icons.star_rounded
                                              : Icons.star_outline_rounded,
                                          size: 34,
                                          color: filled
                                              ? KinovaColors.goldRich
                                              : KinovaColors.sand,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        Text(
                          product.description,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 18),
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
                  CartFly.fly(context, product.imageUrl);
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: const Duration(milliseconds: 1400),
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
