import 'package:flutter/foundation.dart' hide Category;
import 'package:kinova_mobile/api/api_client.dart';
import 'package:kinova_mobile/api/api_mappers.dart';
import 'package:kinova_mobile/models/app_settings.dart';
import 'package:kinova_mobile/models/models.dart';

class CatalogController extends ChangeNotifier {
  CatalogController(this._api);

  final ApiClient _api;

  List<Category> _categories = [];
  List<Product> _products = [];
  List<HeroSlide> _heroSlides = [];
  AppSettings _settings = const AppSettings();
  bool _loading = false;
  String? _error;

  List<Category> get categories => List.unmodifiable(_categories);
  List<Product> get products => List.unmodifiable(_products);
  List<HeroSlide> get heroSlides => List.unmodifiable(_heroSlides);
  AppSettings get settings => _settings;
  bool get loading => _loading;
  String? get error => _error;
  bool get isReady => _products.isNotEmpty;

  List<Product> get featured =>
      _products.where((p) => p.isFeatured).toList(growable: false);

  List<Product> get news =>
      _products.where((p) => p.isNew).toList(growable: false);

  List<Product> byCategory(String categoryId) => _products
      .where((p) => p.categoryId == categoryId)
      .toList(growable: false);

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

  void patchProductRating(String productId, double average, int count) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index < 0) return;
    _products[index] = _products[index].copyWith(
      rating: average,
      ratingsCount: count,
    );
    notifyListeners();
  }

  Future<void> load() async {
    // Laisse finir le frame en cours (évite markNeedsBuild pendant build).
    await Future<void>.delayed(Duration.zero);

    _loading = true;
    _error = null;
    notifyListeners();

    await _loadSettings();

    try {
      final results = await Future.wait([
        _api.get('/categories'),
        _fetchAllProducts(),
        _api.get('/hero-slides'),
      ]);
      final catsRaw = results[0];
      final productList = results[1] as List;
      final slidesRaw = results[2];

      final catList = (catsRaw is Map && catsRaw['data'] is List)
          ? catsRaw['data'] as List
          : (catsRaw is List ? catsRaw : const []);

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

  /// L'API pagine les produits : on récupère toutes les pages.
  Future<List> _fetchAllProducts() async {
    final all = [];
    var page = 1;
    var lastPage = 1;
    do {
      final raw = await _api.get(
        '/products',
        query: {'per_page': '200', 'page': '$page'},
      );
      if (raw is List) return raw;
      if (raw is! Map || raw['data'] is! List) break;
      all.addAll(raw['data'] as List);
      lastPage = int.tryParse('${raw['last_page'] ?? 1}') ?? 1;
      page++;
    } while (page <= lastPage && page <= 25);
    return all;
  }

  Future<void> refreshSettings() async {
    await _loadSettings();
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    try {
      final raw = await _api.get('/settings');
      if (raw is Map && raw['data'] is Map) {
        _settings = AppSettings.fromJson(
          Map<String, dynamic>.from(raw['data'] as Map),
        );
      }
    } catch (_) {
      // Garde les derniers paramètres connus (ou les valeurs par défaut).
    }
  }
}
