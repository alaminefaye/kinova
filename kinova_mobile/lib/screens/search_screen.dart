import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kinova_mobile/state/catalog_controller.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';
import 'package:kinova_mobile/widgets/motion.dart';
import 'package:kinova_mobile/widgets/product_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();
    final results = catalog.search(_query);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: KinovaColors.background,
      body: Column(
        children: [
          // ── Header sombre incurvé, assorti au home ──
          Container(
            padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 22),
            decoration: const BoxDecoration(
              gradient: KinovaColors.darkLuxuryGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
                _RoundIconButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: KinovaColors.gold.withOpacity(0.4),
                        width: 1,
                      ),
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
                            controller: _controller,
                            autofocus: true,
                            cursorColor: KinovaColors.gold,
                            style: const TextStyle(
                              color: KinovaColors.cream,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Rechercher une pièce…',
                              hintStyle: TextStyle(
                                color: KinovaColors.cream.withOpacity(0.45),
                                fontSize: 14,
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
                              _controller.clear();
                              setState(() => _query = '');
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: KinovaColors.goldLight,
                                size: 14,
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

          // ── Résultats ──
          Expanded(
            child: _query.isEmpty
                ? _SearchSuggestions(
                    onPick: (term) {
                      _controller.text = term;
                      setState(() => _query = term);
                    },
                  )
                : results.isEmpty
                    ? const _EmptyResults()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(18, 16, 18, 4),
                            child: Text(
                              '${results.length} résultat${results.length > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color:
                                    KinovaColors.mutedBrown.withOpacity(0.9),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GridView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              physics: const BouncingScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 18,
                                crossAxisSpacing: 14,
                                childAspectRatio: 0.62,
                              ),
                              itemCount: results.length,
                              itemBuilder: (context, index) => FadeSlideIn(
                                delay: Duration(milliseconds: 30 * index),
                                child: ProductCard(product: results[index]),
                              ),
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          shape: BoxShape.circle,
          border: Border.all(
            color: KinovaColors.gold.withOpacity(0.35),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: KinovaColors.goldLight,
          size: 20,
        ),
      ),
    );
  }
}

/// Suggestions affichées avant la première frappe.
class _SearchSuggestions extends StatelessWidget {
  const _SearchSuggestions({required this.onPick});

  final ValueChanged<String> onPick;

  static const _terms = [
    'Sac',
    'Montre',
    'Parfum',
    'Bijoux',
    'Cuir',
    'Or',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
      physics: const BouncingScrollPhysics(),
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 2,
              decoration: BoxDecoration(
                gradient: KinovaColors.goldGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'SUGGESTIONS',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.2,
                color: KinovaColors.mutedBrown.withOpacity(0.9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final term in _terms)
              GestureDetector(
                onTap: () => onPick(term),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: KinovaColors.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: KinovaColors.gold.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: KinovaColors.softShadow,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.north_east_rounded,
                        size: 12,
                        color: KinovaColors.gold,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        term,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: KinovaColors.brown,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
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
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun résultat',
            style: TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: KinovaColors.brown,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Essayez un autre mot-clé',
            style: TextStyle(
              fontSize: 12.5,
              color: KinovaColors.mutedBrown.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}
