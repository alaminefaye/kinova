import 'package:flutter/foundation.dart';
import 'package:kinova_mobile/models/models.dart';

class FavoritesController extends ChangeNotifier {
  final Set<String> _ids = {};

  Set<String> get ids => Set.unmodifiable(_ids);

  bool isFavorite(String productId) => _ids.contains(productId);

  void toggle(Product product) {
    if (_ids.contains(product.id)) {
      _ids.remove(product.id);
    } else {
      _ids.add(product.id);
    }
    notifyListeners();
  }
}
