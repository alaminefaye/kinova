import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kinova_mobile/models/models.dart';
import 'package:kinova_mobile/state/catalog_controller.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';
import 'package:kinova_mobile/widgets/kinova_loader.dart';
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
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialCategoryId;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> _products(CatalogController catalog) {
    var list = _categoryId == null
        ? catalog.products
        : catalog.byCategory(_categoryId!);
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      list = list
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                p.description.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();
    final products = _products(catalog);

    final body = Column(
      children: [
        if (catalog.error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              catalog.error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        // ── Barre de recherche intégrée ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: KinovaColors.surface,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: KinovaColors.gold.withOpacity(0.35),
                width: 1,
              ),
              boxShadow: KinovaColors.softShadow,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: KinovaColors.gold,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    cursorColor: KinovaColors.gold,
                    style: const TextStyle(
                      color: KinovaColors.brown,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Rechercher dans la boutique…',
                      hintStyle: TextStyle(
                        color: KinovaColors.mutedBrown.withOpacity(0.7),
                        fontSize: 13.5,
                      ),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                if (_query.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: KinovaColors.surfaceMuted,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: KinovaColors.gold.withOpacity(0.3),
                          width: 0.8,
                        ),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: KinovaColors.brown,
                        size: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
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
              ...catalog.categories.map(
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
          child: catalog.loading && products.isEmpty
              ? const KinovaLoader(message: 'Chargement de la boutique')
              : products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: KinovaColors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: KinovaColors.gold.withOpacity(0.35),
                                width: 1,
                              ),
                              boxShadow: KinovaColors.softShadow,
                            ),
                            child: const Icon(
                              Icons.search_off_rounded,
                              color: KinovaColors.gold,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Aucune pièce trouvée',
                            style: TextStyle(
                              fontFamily: 'PlayfairDisplay',
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: KinovaColors.brown,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Essayez un autre mot-clé ou univers',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  KinovaColors.mutedBrown.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                  onRefresh: () => catalog.load(),
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                        heroTag: 'catalog-${products[index].id}',
                      ),
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
