import 'package:flutter/foundation.dart';
import 'package:kinova_mobile/api/api_client.dart';
import 'package:kinova_mobile/api/api_mappers.dart';
import 'package:kinova_mobile/models/models.dart';

class FavoritesController extends ChangeNotifier {
  FavoritesController(this._api);

  final ApiClient _api;
  final Set<String> _ids = {};
  final Map<String, Product> _products = {};
  bool _syncing = false;

  Set<String> get ids => Set.unmodifiable(_ids);
  List<Product> get products => _ids
      .map((id) => _products[id])
      .whereType<Product>()
      .toList(growable: false);
  bool get syncing => _syncing;

  bool isFavorite(String productId) => _ids.contains(productId);

  Future<void> loadFromApi() async {
    if (_api.token == null) return;
    _syncing = true;
    notifyListeners();
    try {
      final res = await _api.get('/customer/favorites');
      final list = res is Map && res['data'] is List ? res['data'] as List : const [];
      _ids.clear();
      _products.clear();
      for (final item in list.whereType<Map>()) {
        final product = ApiMappers.product(Map<String, dynamic>.from(item));
        _ids.add(product.id);
        _products[product.id] = product;
      }
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  Future<void> toggle(Product product) async {
    final id = product.id;
    final wasFavorite = _ids.contains(id);

    if (wasFavorite) {
      _ids.remove(id);
      _products.remove(id);
    } else {
      _ids.add(id);
      _products[id] = product;
    }
    notifyListeners();

    if (_api.token == null) return;

    try {
      if (wasFavorite) {
        await _api.delete('/customer/favorites/$id');
      } else {
        await _api.post('/customer/favorites', body: {
          'product_id': int.tryParse(id) ?? id,
        });
      }
    } catch (_) {
      // rollback
      if (wasFavorite) {
        _ids.add(id);
        _products[id] = product;
      } else {
        _ids.remove(id);
        _products.remove(id);
      }
      notifyListeners();
    }
  }

  void clearLocal() {
    _ids.clear();
    _products.clear();
    notifyListeners();
  }
}
