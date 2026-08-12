import 'package:flutter/foundation.dart';
import 'package:kinova_mobile/api/api_client.dart';
import 'package:kinova_mobile/api/api_mappers.dart';
import 'package:kinova_mobile/models/models.dart';

class CartController extends ChangeNotifier {
  CartController(this._api);

  final ApiClient _api;
  final List<CartItem> _items = [];
  final List<Order> _orders = [];

  List<CartItem> get items => List.unmodifiable(_items);
  List<Order> get orders => List.unmodifiable(_orders);

  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);

  double get subtotal => _items.fold(0, (sum, i) => sum + i.lineTotal);

  double get shipping => _items.isEmpty ? 0 : (subtotal >= 100 ? 0 : 6.5);

  double get total => subtotal + shipping;

  void add(Product product, {int quantity = 1}) {
    final index = _items.indexWhere((i) => i.product.id == product.id);
    if (index >= 0) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    notifyListeners();
  }

  void remove(String productId) {
    _items.removeWhere((i) => i.product.id == productId);
    notifyListeners();
  }

  void setQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      remove(productId);
      return;
    }
    final index = _items.indexWhere((i) => i.product.id == productId);
    if (index >= 0) {
      _items[index].quantity = quantity;
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  void setOrders(List<Order> orders) {
    _orders
      ..clear()
      ..addAll(orders);
    notifyListeners();
  }

  Future<Order> placeOrder({
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    required String address,
    required String city,
    required String paymentMethod,
  }) async {
    final res = await _api.post('/orders', body: {
      'customer_name': customerName,
      'customer_phone': customerPhone,
      if (customerEmail != null && customerEmail.isNotEmpty)
        'customer_email': customerEmail,
      'address': address,
      'city': city,
      'payment_method': paymentMethod,
      'items': _items
          .map(
            (i) => {
              'product_id': int.tryParse(i.product.id) ?? i.product.id,
              'quantity': i.quantity,
            },
          )
          .toList(),
    });

    final data = res is Map && res['data'] is Map
        ? Map<String, dynamic>.from(res['data'] as Map)
        : Map<String, dynamic>.from(res as Map);

    final order = ApiMappers.order(data);
    _orders.insert(0, order);
    clear();
    return order;
  }
}
