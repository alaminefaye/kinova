import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:kinova_mobile/api/api_client.dart';
import 'package:kinova_mobile/api/api_mappers.dart';
import 'package:kinova_mobile/models/app_settings.dart';
import 'package:kinova_mobile/models/models.dart';
import 'package:kinova_mobile/services/cart_reminder_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartController extends ChangeNotifier {
  CartController(this._api) {
    unawaited(_loadSaved());
  }

  static const _storageKey = 'kinova_cart_v1';
  static const _maxAge = Duration(days: 14);

  final ApiClient _api;
  AppSettings settings = const AppSettings();
  final List<CartItem> _items = [];
  final List<Order> _orders = [];

  /// Panier sauvegardé, en attente du catalogue pour être reconstruit.
  List<Map<String, dynamic>>? _saved;
  List<Product> _catalog = const [];

  List<CartItem> get items => List.unmodifiable(_items);
  List<Order> get orders => List.unmodifiable(_orders);

  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);

  double get subtotal => _items.fold(0, (sum, i) => sum + i.lineTotal);

  double get shipping => shippingFor();

  double get total => subtotal + shipping;

  /// Quantité maximale commandable (stock produit, taille et couleur choisies).
  static int maxQuantity(
    Product product, {
    String? selectedSize,
    String? selectedColor,
  }) {
    var max = product.effectiveStock;
    for (final s in product.effectiveSizes) {
      if (s.name == selectedSize && s.stock < max) max = s.stock;
    }
    for (final c in product.effectiveColors) {
      if (c.name == selectedColor && c.stock < max) max = c.stock;
    }
    return max.clamp(0, 999);
  }

  void add(
    Product product, {
    int quantity = 1,
    String? selectedSize,
    String? selectedColor,
  }) {
    final index = _items.indexWhere(
      (i) =>
          i.product.id == product.id &&
          i.selectedSize == selectedSize &&
          i.selectedColor == selectedColor,
    );
    final max = maxQuantity(
      product,
      selectedSize: selectedSize,
      selectedColor: selectedColor,
    );
    if (index >= 0) {
      _items[index].quantity = (_items[index].quantity + quantity).clamp(
        1,
        max < 1 ? 1 : max,
      );
    } else {
      _items.add(
        CartItem(
          product: product,
          quantity: quantity.clamp(1, max < 1 ? 1 : max),
          selectedSize: selectedSize,
          selectedColor: selectedColor,
        ),
      );
    }
    _changed();
  }

  void remove(String productId) {
    _items.removeWhere((i) => i.product.id == productId);
    _changed();
  }

  void removeItem(CartItem item) {
    _items.remove(item);
    _changed();
  }

  void setItemQuantity(CartItem item, int quantity) {
    if (quantity <= 0) {
      _items.remove(item);
      _changed();
      return;
    }
    final max = maxQuantity(
      item.product,
      selectedSize: item.selectedSize,
      selectedColor: item.selectedColor,
    );
    item.quantity = quantity.clamp(1, max < 1 ? 1 : max);
    _changed();
  }

  void setQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      remove(productId);
      return;
    }
    final index = _items.indexWhere((i) => i.product.id == productId);
    if (index >= 0) {
      _items[index].quantity = quantity;
      _changed();
    }
  }

  void clear() {
    _items.clear();
    _changed();
  }

  /// Sauvegarde le panier et reprogramme le rappel « panier non finalisé ».
  void _changed() {
    notifyListeners();
    unawaited(_persist());
    if (_items.isEmpty) {
      unawaited(CartReminderService.cancel());
    } else {
      unawaited(
        CartReminderService.schedule(
          itemCount: itemCount,
          firstProductName: _items.first.product.name,
        ),
      );
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_items.isEmpty) {
        await prefs.remove(_storageKey);
        return;
      }
      await prefs.setString(
        _storageKey,
        jsonEncode({
          'saved_at': DateTime.now().toIso8601String(),
          'items': [
            for (final i in _items)
              {
                'product_id': i.product.id,
                'quantity': i.quantity,
                'size': i.selectedSize,
                'color': i.selectedColor,
              },
          ],
        }),
      );
    } catch (e) {
      debugPrint('Panier non sauvegardé : $e');
    }
  }

  Future<void> _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) return;
      final data = jsonDecode(raw);
      final savedAt = DateTime.tryParse('${data['saved_at']}');
      if (savedAt == null || DateTime.now().difference(savedAt) > _maxAge) {
        await prefs.remove(_storageKey);
        return;
      }
      _saved = [
        for (final e in (data['items'] as List? ?? const []))
          if (e is Map) Map<String, dynamic>.from(e),
      ];
      _restore();
    } catch (e) {
      debugPrint('Panier sauvegardé illisible : $e');
    }
  }

  /// Appelé à chaque mise à jour du catalogue (ProxyProvider).
  void attachCatalog(List<Product> products) {
    if (products.isEmpty || identical(products, _catalog)) return;
    _catalog = products;
    if (_saved != null) scheduleMicrotask(_restore);
  }

  void _restore() {
    final saved = _saved;
    if (saved == null || _catalog.isEmpty) return;
    _saved = null;
    if (_items.isNotEmpty) return;

    final byId = {for (final p in _catalog) p.id: p};
    for (final e in saved) {
      final product = byId['${e['product_id']}'];
      if (product == null) continue;
      final size = e['size'] as String?;
      final color = e['color'] as String?;
      final max = maxQuantity(
        product,
        selectedSize: size,
        selectedColor: color,
      );
      if (max < 1) continue;
      final qty = (int.tryParse('${e['quantity']}') ?? 1).clamp(1, max);
      _items.add(
        CartItem(
          product: product,
          quantity: qty,
          selectedSize: size,
          selectedColor: color,
        ),
      );
    }
    notifyListeners();
    unawaited(_persist());
  }

  void setOrders(List<Order> orders) {
    _orders
      ..clear()
      ..addAll(orders);
    notifyListeners();
  }

  double shippingFor({bool isDelivery = true}) => _items.isEmpty
      ? 0
      : settings.shippingFor(subtotal, isDelivery: isDelivery);

  Future<Order> placeOrder({
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    bool isDelivery = true,
    String? address,
    String? city,
    double? latitude,
    double? longitude,
    String? deliveryDetails,
    String paymentMethod = 'cod',
  }) async {
    final res = await _api.post(
      '/orders',
      body: {
        'customer_name': customerName,
        'customer_phone': customerPhone,
        if (customerEmail != null && customerEmail.isNotEmpty)
          'customer_email': customerEmail,
        'is_delivery': isDelivery,
        'address': isDelivery ? (address ?? '') : 'Retrait en boutique KINOVA',
        'city': isDelivery ? (city ?? 'Abidjan') : 'Abidjan',
        if (isDelivery && latitude != null && longitude != null) ...{
          'latitude': latitude,
          'longitude': longitude,
        },
        if (isDelivery && deliveryDetails != null && deliveryDetails.isNotEmpty)
          'delivery_details': deliveryDetails,
        'payment_method': paymentMethod,
        'items': _items
            .map(
              (i) => {
                'product_id': int.tryParse(i.product.id) ?? i.product.id,
                'quantity': i.quantity,
                if (i.selectedSize != null) 'selected_size': i.selectedSize,
                if (i.selectedColor != null) 'selected_color': i.selectedColor,
              },
            )
            .toList(),
      },
    );

    final data = res is Map && res['data'] is Map
        ? Map<String, dynamic>.from(res['data'] as Map)
        : Map<String, dynamic>.from(res as Map);

    final order = ApiMappers.order(data);
    _orders.insert(0, order);
    clear();
    return order;
  }
}
