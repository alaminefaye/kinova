import 'package:flutter/foundation.dart';
import 'package:kinova_mobile/models/models.dart';

class CartController extends ChangeNotifier {
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

  Order placeOrder() {
    final order = Order(
      id: 'KV-${DateTime.now().millisecondsSinceEpoch % 100000}',
      items: _items
          .map((i) => CartItem(product: i.product, quantity: i.quantity))
          .toList(),
      total: total,
      createdAt: DateTime.now(),
      status: 'En préparation',
    );
    _orders.insert(0, order);
    clear();
    return order;
  }
}
