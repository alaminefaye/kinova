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

  double get shipping => _items.isEmpty ? 0 : (subtotal >= 50000 ? 0 : 2500);

  double get total => subtotal + shipping;

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
    if (index >= 0) {
      _items[index].quantity += quantity;
    } else {
      _items.add(
        CartItem(
          product: product,
          quantity: quantity,
          selectedSize: selectedSize,
          selectedColor: selectedColor,
        ),
      );
    }
    notifyListeners();
  }

  void remove(String productId) {
    _items.removeWhere((i) => i.product.id == productId);
    notifyListeners();
  }

  void removeItem(CartItem item) {
    _items.remove(item);
    notifyListeners();
  }

  void setItemQuantity(CartItem item, int quantity) {
    if (quantity <= 0) {
      _items.remove(item);
      notifyListeners();
      return;
    }
    item.quantity = quantity;
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
              if (i.selectedSize != null) 'selected_size': i.selectedSize,
              if (i.selectedColor != null) 'selected_color': i.selectedColor,
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
