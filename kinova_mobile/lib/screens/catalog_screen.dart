import 'package:flutter/material.dart';
import 'package:kinova_mobile/data/shop_data.dart';
import 'package:kinova_mobile/models/models.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';
import 'package:kinova_mobile/widgets/motion.dart';
import 'package:kinova_mobile/widgets/product_card.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({
    super.key,
    this.embedded = true,
    this.initialCategoryId,
  });

  final bool embedded;
  final String? initialCategoryId;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late String? _categoryId;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialCategoryId;
  }

  List<Product> get _products {
    if (_categoryId == null) return ShopData.products;
    return ShopData.byCategory(_categoryId!);
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _Chip(
                label: 'Tout',
                selected: _categoryId == null,
                onTap: () => setState(() => _categoryId = null),
              ),
              ...ShopData.categories.map(
                (c) => _Chip(
                  label: c.name,
                  selected: _categoryId == c.id,
                  onTap: () => setState(() => _categoryId = c.id),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 14,
              childAspectRatio: 0.65,
            ),
            itemCount: _products.length,
            itemBuilder: (context, index) => FadeSlideIn(
              delay: Duration(milliseconds: 40 * index),
              child: ProductCard(
                product: _products[index],
                heroTag: 'catalog-${_products[index].id}',
              ),
            ),
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Boutique')),
        body: body,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Boutique'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: body,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: KinovaColors.brown,
        backgroundColor: KinovaColors.surface,
        elevation: selected ? 2 : 0,
        shadowColor: KinovaColors.brown.withOpacity(0.2),
        labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected ? KinovaColors.cream : KinovaColors.brown,
              letterSpacing: 0.8,
              fontSize: 11.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected
                ? KinovaColors.brown
                : KinovaColors.gold.withOpacity(0.25),
            width: 1,
          ),
        ),
        showCheckmark: false,
      ),
    );
  }
}
