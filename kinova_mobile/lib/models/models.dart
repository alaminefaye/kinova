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
    this.role = 'customer',
    this.roles = const [],
    this.permissions = const [],
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
  final String role;
  final List<String> roles;
  final List<String> permissions;

  bool get isAdmin =>
      role == 'admin' ||
      roles.contains('admin') ||
      roles.contains('super-admin') ||
      roles.contains('manager');

  bool get isSuperAdmin =>
      roles.contains('super-admin') || (role == 'admin' && roles.isEmpty);

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final email = json['email']?.toString();
    final avatar = json['avatar_url']?.toString();
    final resolved = (avatar == null || avatar.isEmpty)
        ? null
        : ApiConfig.resolveMediaUrl(avatar);

    final rawRoles = json['roles'];
    final List<String> parsedRoles = [];
    if (rawRoles is List) {
      for (final r in rawRoles) {
        if (r is String) {
          parsedRoles.add(r);
        } else if (r is Map && r['name'] != null) {
          parsedRoles.add(r['name'].toString());
        }
      }
    }

    final rawPerms = json['permissions'];
    final List<String> parsedPerms = [];
    if (rawPerms is List) {
      for (final p in rawPerms) {
        if (p is String) {
          parsedPerms.add(p);
        } else if (p is Map && p['name'] != null) {
          parsedPerms.add(p['name'].toString());
        }
      }
    }

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
      role: (json['role'] ?? (parsedRoles.isNotEmpty ? parsedRoles.first : 'customer')).toString(),
      roles: parsedRoles,
      permissions: parsedPerms,
    );
  }
}

class AdminDailySale {
  const AdminDailySale({
    required this.date,
    required this.label,
    required this.amount,
    required this.count,
  });

  final String date;
  final String label;
  final double amount;
  final int count;

  factory AdminDailySale.fromJson(Map<String, dynamic> json) {
    return AdminDailySale(
      date: (json['date'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.tryParse('${json['amount']}') ?? 0.0,
      count: int.tryParse('${json['count'] ?? 0}') ?? 0,
    );
  }
}

class AdminLowStockProduct {
  const AdminLowStockProduct({
    required this.id,
    required this.name,
    required this.stock,
    required this.price,
    this.promoPrice,
    this.imageUrl,
  });

  final String id;
  final String name;
  final int stock;
  final double price;
  final double? promoPrice;
  final String? imageUrl;

  factory AdminLowStockProduct.fromJson(Map<String, dynamic> json) {
    final rawImg = json['image_url']?.toString();
    return AdminLowStockProduct(
      id: '${json['id']}',
      name: (json['name'] ?? '').toString(),
      stock: int.tryParse('${json['stock'] ?? 0}') ?? 0,
      price: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : double.tryParse('${json['price']}') ?? 0.0,
      promoPrice: json['promo_price'] != null
          ? double.tryParse('${json['promo_price']}')
          : null,
      imageUrl: (rawImg != null && rawImg.isNotEmpty)
          ? ApiConfig.resolveMediaUrl(rawImg)
          : null,
    );
  }
}

class AdminOrderSummary {
  const AdminOrderSummary({
    required this.id,
    required this.reference,
    required this.customerName,
    this.customerPhone,
    required this.total,
    required this.status,
    required this.createdAt,
    this.itemsCount = 0,
  });

  final String id;
  final String reference;
  final String customerName;
  final String? customerPhone;
  final double total;
  final String status;
  final DateTime createdAt;
  final int itemsCount;

  factory AdminOrderSummary.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    int count = 0;
    if (rawItems is List) {
      count = rawItems.length;
    }

    final rawUser = json['user'] is Map ? json['user'] as Map : null;
    final custName = json['customer_name']?.toString() ??
        rawUser?['name']?.toString() ??
        'Client';
    final custPhone = json['customer_phone']?.toString() ??
        rawUser?['phone']?.toString();

    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['created_at']?.toString() ?? '');
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return AdminOrderSummary(
      id: '${json['id']}',
      reference: json['reference']?.toString() ?? '#CMD-${json['id']}',
      customerName: custName,
      customerPhone: custPhone,
      total: (json['total'] is num)
          ? (json['total'] as num).toDouble()
          : double.tryParse('${json['total']}') ?? 0.0,
      status: (json['status'] ?? 'pending').toString(),
      createdAt: parsedDate,
      itemsCount: count,
    );
  }
}

class AdminDashboardData {
  const AdminDashboardData({
    required this.todayRevenue,
    required this.todayOrdersCount,
    required this.monthRevenue,
    required this.monthOrdersCount,
    required this.totalRevenue,
    required this.ordersCount,
    required this.pendingOrders,
    required this.processingOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.totalCustomers,
    required this.newCustomersToday,
    required this.productsCount,
    required this.categoriesCount,
    required this.salesByDay,
    required this.lowStock,
    required this.latestOrders,
  });

  final double todayRevenue;
  final int todayOrdersCount;
  final double monthRevenue;
  final int monthOrdersCount;
  final double totalRevenue;
  final int ordersCount;
  final int pendingOrders;
  final int processingOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final int totalCustomers;
  final int newCustomersToday;
  final int productsCount;
  final int categoriesCount;
  final List<AdminDailySale> salesByDay;
  final List<AdminLowStockProduct> lowStock;
  final List<AdminOrderSummary> latestOrders;

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) {
    final salesList = (json['sales_by_day'] as List<dynamic>? ?? [])
        .map((e) => AdminDailySale.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final lowStockList = (json['low_stock'] as List<dynamic>? ?? [])
        .map((e) => AdminLowStockProduct.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final ordersList = (json['latest_orders'] as List<dynamic>? ?? [])
        .map((e) => AdminOrderSummary.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return AdminDashboardData(
      todayRevenue: (json['today_revenue'] is num)
          ? (json['today_revenue'] as num).toDouble()
          : double.tryParse('${json['today_revenue']}') ?? 0.0,
      todayOrdersCount: int.tryParse('${json['today_orders_count'] ?? 0}') ?? 0,
      monthRevenue: (json['month_revenue'] is num)
          ? (json['month_revenue'] as num).toDouble()
          : double.tryParse('${json['month_revenue']}') ?? 0.0,
      monthOrdersCount: int.tryParse('${json['month_orders_count'] ?? 0}') ?? 0,
      totalRevenue: (json['total_revenue'] is num)
          ? (json['total_revenue'] as num).toDouble()
          : double.tryParse('${json['total_revenue']}') ?? 0.0,
      ordersCount: int.tryParse('${json['orders_count'] ?? 0}') ?? 0,
      pendingOrders: int.tryParse('${json['pending_orders'] ?? 0}') ?? 0,
      processingOrders: int.tryParse('${json['processing_orders'] ?? 0}') ?? 0,
      deliveredOrders: int.tryParse('${json['delivered_orders'] ?? 0}') ?? 0,
      cancelledOrders: int.tryParse('${json['cancelled_orders'] ?? 0}') ?? 0,
      totalCustomers: int.tryParse('${json['total_customers'] ?? 0}') ?? 0,
      newCustomersToday: int.tryParse('${json['new_customers_today'] ?? 0}') ?? 0,
      productsCount: int.tryParse('${json['products_count'] ?? 0}') ?? 0,
      categoriesCount: int.tryParse('${json['categories_count'] ?? 0}') ?? 0,
      salesByDay: salesList,
      lowStock: lowStockList,
      latestOrders: ordersList,
    );
  }
}
