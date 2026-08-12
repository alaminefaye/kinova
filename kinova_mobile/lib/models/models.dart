class Category {
  const Category({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  final String id;
  final String name;
  final String imageUrl;
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    required this.imageUrl,
    this.images = const [],
    this.rating = 4.8,
    this.isNew = false,
    this.isFeatured = false,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final String categoryId;
  final String imageUrl;
  final List<String> images;
  final double rating;
  final bool isNew;
  final bool isFeatured;

  List<String> get gallery => images.isEmpty ? [imageUrl] : images;
}

class CartItem {
  CartItem({
    required this.product,
    this.quantity = 1,
  });

  final Product product;
  int quantity;

  double get lineTotal => product.price * quantity;
}

class Order {
  const Order({
    required this.id,
    required this.items,
    required this.total,
    required this.createdAt,
    required this.status,
  });

  final String id;
  final List<CartItem> items;
  final double total;
  final DateTime createdAt;
  final String status;
}
