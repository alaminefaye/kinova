import 'package:flutter/material.dart';
import 'package:kinova_mobile/data/shop_data.dart';
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
    final results = ShopData.search(_query);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Rechercher…',
            filled: false,
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              onPressed: () {
                _controller.clear();
                setState(() => _query = '');
              },
              icon: const Icon(Icons.close),
            ),
        ],
      ),
      body: results.isEmpty
          ? Center(
              child: Text(
                'Aucun résultat',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
    );
  }
}
