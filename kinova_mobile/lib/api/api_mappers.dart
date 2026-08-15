import 'package:kinova_mobile/models/models.dart';

class ApiMappers {
  ApiMappers._();

  static Category category(Map<String, dynamic> json) {
    return Category(
      id: '${json['id']}',
      name: (json['name'] ?? '').toString(),
      imageUrl: (json['image_url'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
    );
  }

  static HeroSlide heroSlide(Map<String, dynamic> json) {
    return HeroSlide(
      id: '${json['id']}',
      title: (json['title'] ?? '').toString(),
      imageUrl: (json['image_url'] ?? '').toString(),
      tag: (json['tag'] ?? '').toString(),
      ctaLabel: (json['cta_label'] ?? 'DÉCOUVRIR').toString(),
      linkType: (json['link_type'] ?? 'catalog').toString(),
      linkValue: json['link_value']?.toString(),
    );
  }

  static Product product(Map<String, dynamic> json) {
    final gallery = <String>[];
    final rawGallery = json['gallery'];
    if (rawGallery is List) {
      for (final item in rawGallery) {
        if (item != null && item.toString().isNotEmpty) {
          gallery.add(item.toString());
        }
      }
    }

    final imageUrl = (json['image_url'] ?? (gallery.isNotEmpty ? gallery.first : ''))
        .toString();

    final sizes = <ProductSize>[];
    final rawSizes = json['sizes'];
    if (rawSizes is List) {
      for (final item in rawSizes) {
        if (item is Map) {
          final sMap = Map<String, dynamic>.from(item);
          final name = (sMap['name'] ?? '').toString();
          if (name.isNotEmpty) {
            sizes.add(
              ProductSize(
                name: name,
                stock: int.tryParse('${sMap['stock'] ?? 0}') ?? 0,
              ),
            );
          }
        }
      }
    }

    final colors = <ProductColor>[];
    final rawColors = json['colors'];
    if (rawColors is List) {
      for (final item in rawColors) {
        if (item is Map) {
          final cMap = Map<String, dynamic>.from(item);
          final name = (cMap['name'] ?? '').toString();
          if (name.isNotEmpty) {
            colors.add(
              ProductColor(
                name: name,
                hex: cMap['hex']?.toString(),
                stock: int.tryParse('${cMap['stock'] ?? 0}') ?? 0,
              ),
            );
          }
        }
      }
    }

    return Product(
      id: '${json['id']}',
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      price: _toDouble(json['price']),
      promoPrice: json['promo_price'] != null ? _toDouble(json['promo_price']) : null,
      categoryId: '${json['category_id']}',
      imageUrl: imageUrl,
      images: gallery,
      sizes: sizes,
      colors: colors,
      stock: int.tryParse('${json['stock'] ?? 0}') ?? 0,
      rating: _toDouble(json['rating'], fallback: 4.8),
      ratingsCount: int.tryParse('${json['ratings_count'] ?? 0}') ?? 0,
      isNew: json['is_new'] == true || json['is_new'] == 1,
      isFeatured: json['is_featured'] == true || json['is_featured'] == 1,
    );
  }

  static Order order(Map<String, dynamic> json) {
    final items = <CartItem>[];
    final rawItems = json['items'];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final product = Product(
          id: '${map['product_id'] ?? ''}',
          name: (map['product_name'] ?? '').toString(),
          description: '',
          price: _toDouble(map['unit_price']),
          categoryId: '',
          imageUrl: '',
        );
        items.add(
          CartItem(
            product: product,
            quantity: int.tryParse('${map['quantity']}') ?? 1,
            selectedSize: map['selected_size']?.toString(),
            selectedColor: map['selected_color']?.toString(),
          ),
        );
      }
    }

    return Order(
      id: (json['reference'] ?? json['id'] ?? '').toString(),
      items: items,
      total: _toDouble(json['total']),
      createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
      status: _statusLabel((json['status'] ?? 'pending').toString()),
      trackingNumber: json['tracking_number']?.toString(),
      carrier: json['carrier']?.toString(),
    );
  }

  static String _statusLabel(String status) {
    return switch (status) {
      'pending' => 'En attente',
      'processing' => 'En préparation',
      'shipped' => 'Expédiée',
      'delivered' => 'Livrée',
      'cancelled' => 'Annulée',
      _ => status,
    };
  }

  static double _toDouble(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? fallback;
  }
}
