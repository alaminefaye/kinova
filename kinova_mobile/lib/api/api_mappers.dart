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

    final productStock = int.tryParse('${json['stock'] ?? 0}') ?? 0;

    // Stock de variante absent = pas de limite propre (le stock produit s'applique), comme côté serveur.
    int variantStock(Map<String, dynamic> variant) => variant['stock'] == null
        ? productStock
        : int.tryParse('${variant['stock']}') ?? 0;

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
                stock: variantStock(sMap),
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
                stock: variantStock(cMap),
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
      stock: productStock,
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

    final statusCode = (json['status'] ?? 'pending').toString();
    String? str(String key) {
      final v = json[key]?.toString();
      return (v == null || v.isEmpty) ? null : v;
    }

    return Order(
      id: (json['reference'] ?? json['id'] ?? '').toString(),
      items: items,
      total: _toDouble(json['total']),
      createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
      status: _statusLabel(statusCode),
      trackingNumber: str('tracking_number'),
      carrier: str('carrier'),
      statusCode: statusCode,
      subtotal: _toDouble(json['subtotal']),
      shipping: _toDouble(json['shipping']),
      isDelivery: json['is_delivery'] == null
          ? true
          : (json['is_delivery'] == true || '${json['is_delivery']}' == '1'),
      customerName: str('customer_name'),
      customerPhone: str('customer_phone'),
      address: str('address'),
      city: str('city'),
      deliveryDetails: str('delivery_details'),
      latitude: double.tryParse('${json['latitude']}'),
      longitude: double.tryParse('${json['longitude']}'),
      mapsUrl: str('maps_url'),
      paymentStatus: str('payment_status') ?? 'unpaid',
      paidAt: DateTime.tryParse('${json['paid_at']}'),
      invoiceNumber: str('invoice_number'),
      invoiceStatus: str('invoice_status') ?? 'provisional',
      invoiceUrl: str('invoice_url'),
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
