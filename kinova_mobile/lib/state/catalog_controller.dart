import 'package:flutter/foundation.dart' hide Category;
import 'package:kinova_mobile/api/api_client.dart';
import 'package:kinova_mobile/api/api_mappers.dart';
import 'package:kinova_mobile/models/models.dart';

class CatalogController extends ChangeNotifier {
  CatalogController(this._api);

  final ApiClient _api;

  List<Category> _categories = [];
  List<Product> _products = [];
  List<HeroSlide> _heroSlides = [];
  bool _loading = false;
  String? _error;

  List<Category> get categories => List.unmodifiable(_categories);
  List<Product> get products => List.unmodifiable(_products);
  List<HeroSlide> get heroSlides => List.unmodifiable(_heroSlides);
  bool get loading => _loading;
  String? get error => _error;
  bool get isReady => _products.isNotEmpty;

  List<Product> get featured =>
      _products.where((p) => p.isFeatured).toList(growable: false);

  List<Product> get news =>
      _products.where((p) => p.isNew).toList(growable: false);

  List<Product> byCategory(String categoryId) =>
      _products.where((p) => p.categoryId == categoryId).toList(growable: false);

  List<Product> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return products;
    return _products
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  Product? byId(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> load() async {
    // Laisse finir le frame en cours (évite markNeedsBuild pendant build).
    await Future<void>.delayed(Duration.zero);

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final catsRaw = await _api.get('/categories');
      final productsRaw = await _api.get('/products');
      final slidesRaw = await _api.get('/hero-slides');

      final catList = (catsRaw is Map && catsRaw['data'] is List)
          ? catsRaw['data'] as List
          : (catsRaw is List ? catsRaw : const []);

      final productList = (productsRaw is Map && productsRaw['data'] is List)
          ? productsRaw['data'] as List
          : (productsRaw is List ? productsRaw : const []);

      final slideList = (slidesRaw is Map && slidesRaw['data'] is List)
          ? slidesRaw['data'] as List
          : (slidesRaw is List ? slidesRaw : const []);

      _categories = catList
          .whereType<Map>()
          .map((e) => ApiMappers.category(Map<String, dynamic>.from(e)))
          .toList();

      _products = productList
          .whereType<Map>()
          .map((e) => ApiMappers.product(Map<String, dynamic>.from(e)))
          .toList();

      _heroSlides = slideList
          .whereType<Map>()
          .map((e) => ApiMappers.heroSlide(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
