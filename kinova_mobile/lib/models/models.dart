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

class ProductSize {
  const ProductSize({
    required this.name,
    this.stock = 0,
  });

  final String name;
  final int stock;
}

class ProductColor {
  const ProductColor({
    required this.name,
    this.hex,
    this.stock = 0,
  });

  final String name;
  final String? hex;
  final int stock;
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.promoPrice,
    required this.categoryId,
    required this.imageUrl,
    this.images = const [],
    this.sizes = const [],
    this.colors = const [],
    this.stock = 0,
    this.rating = 4.8,
    this.ratingsCount = 0,
    this.isNew = false,
    this.isFeatured = false,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final double? promoPrice;
  final String categoryId;
  final String imageUrl;
  final List<String> images;
  final List<ProductSize>? sizes;
  final List<ProductColor>? colors;
  final int? stock;
  final double rating;
  final int ratingsCount;
  final bool isNew;
  final bool isFeatured;

  int get effectiveStock => stock ?? 0;
  List<ProductSize> get effectiveSizes => sizes ?? const [];
  List<ProductColor> get effectiveColors => colors ?? const [];

  bool get hasPromo => promoPrice != null && promoPrice! > 0 && promoPrice! < price;

  double get effectivePrice => hasPromo ? promoPrice! : price;

  int get discountPercent =>
      hasPromo ? (((price - promoPrice!) / price) * 100).round() : 0;

  List<ProductSize> get availableSizes =>
      effectiveSizes.where((s) => s.stock > 0).toList();

  List<ProductColor> get availableColors =>
      effectiveColors.where((c) => c.stock > 0).toList();

  bool get isOutOfStock =>
      effectiveStock <= 0 ||
      (effectiveSizes.isNotEmpty && availableSizes.isEmpty) ||
      (effectiveColors.isNotEmpty && availableColors.isEmpty);

  List<String> get gallery => images.isEmpty ? [imageUrl] : images;

  Product copyWith({
    double? rating,
    int? ratingsCount,
    double? promoPrice,
    int? stock,
    List<ProductSize>? sizes,
    List<ProductColor>? colors,
  }) {
    return Product(
      id: id,
      name: name,
      description: description,
      price: price,
      promoPrice: promoPrice ?? this.promoPrice,
      categoryId: categoryId,
      imageUrl: imageUrl,
      images: images,
      sizes: sizes ?? this.sizes,
      colors: colors ?? this.colors,
      stock: stock ?? this.stock,
      rating: rating ?? this.rating,
      ratingsCount: ratingsCount ?? this.ratingsCount,
      isNew: isNew,
      isFeatured: isFeatured,
    );
  }
}

class CartItem {
  CartItem({
    required this.product,
    this.quantity = 1,
    this.selectedSize,
    this.selectedColor,
  });

  final Product product;
  int quantity;
  final String? selectedSize;
  final String? selectedColor;

  double get lineTotal => product.effectivePrice * quantity;
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
