import 'package:kinova_mobile/api/api_config.dart';

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.slug = '',
  });

  final String id;
  final String name;
  final String imageUrl;
  final String slug;
}

class HeroSlide {
  const HeroSlide({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.tag = '',
    this.ctaLabel = 'DÉCOUVRIR',
    this.linkType = 'catalog',
    this.linkValue,
  });

  final String id;
  final String title;
  final String imageUrl;
  final String tag;
  final String ctaLabel;
  final String linkType;
  final String? linkValue;
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
    this.trackingNumber,
    this.carrier,
  });

  final String id;
  final List<CartItem> items;
  final double total;
  final DateTime createdAt;
  final String status;
  final String? trackingNumber;
  final String? carrier;
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.avatarUrl,
    this.address,
    this.city,
    this.loyaltyPoints = 0,
    this.vipTier = 'standard',
  });

  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String? address;
  final String? city;
  final int loyaltyPoints;
  final String vipTier;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final email = json['email']?.toString();
    final avatar = json['avatar_url']?.toString();
    final resolved = (avatar == null || avatar.isEmpty)
        ? null
        : ApiConfig.resolveMediaUrl(avatar);
    return AppUser(
      id: '${json['id']}',
      name: (json['name'] ?? '').toString(),
      email: (email == null || email.isEmpty) ? null : email,
      phone: json['phone']?.toString(),
      avatarUrl: (resolved == null || resolved.isEmpty) ? null : resolved,
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      loyaltyPoints: int.tryParse('${json['loyalty_points'] ?? 0}') ?? 0,
      vipTier: (json['vip_tier'] ?? 'standard').toString(),
    );
  }
}
