import 'package:kinova_mobile/models/models.dart';

class ShopData {
  ShopData._();

  static const categories = <Category>[
    Category(
      id: 'beauty',
      name: 'Beauté',
      imageUrl:
          'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=450&q=70',
    ),
    Category(
      id: 'fashion',
      name: 'Mode',
      imageUrl:
          'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=450&q=70',
    ),
    Category(
      id: 'home',
      name: 'Maison',
      imageUrl:
          'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=450&q=70',
    ),
    Category(
      id: 'accessories',
      name: 'Accessoires',
      imageUrl:
          'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=450&q=70',
    ),
  ];

  static const products = <Product>[
    Product(
      id: 'p1',
      name: 'Sérum Rose Dorée',
      description:
          'Sérum lumineux à la rose et à l’or, pour une peau hydratée et éclatante. Texture soyeuse, finition naturelle.',
      price: 48,
      categoryId: 'beauty',
      imageUrl:
          'https://images.unsplash.com/photo-1571781926291-c77df809e0b0?w=450&q=70',
      images: [
        'https://images.unsplash.com/photo-1571781926291-c77df809e0b0?w=450&q=70',
        'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=450&q=70',
      ],
      isNew: true,
      isFeatured: true,
      rating: 4.9,
    ),
    Product(
      id: 'p2',
      name: 'Sac Cuir Sable',
      description:
          'Sac en cuir grainé couleur sable, finitions or rose. Porté main ou bandoulière.',
      price: 189,
      categoryId: 'fashion',
      imageUrl:
          'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=450&q=70',
      isFeatured: true,
      rating: 4.8,
    ),
    Product(
      id: 'p3',
      name: 'Bougie Ambre',
      description:
          'Bougie parfumée ambre & vanille, cire végétale. Autonomie environ 45 heures.',
      price: 32,
      categoryId: 'home',
      imageUrl:
          'https://images.unsplash.com/photo-1603006905003-be21c6d3c0d6?w=450&q=70',
      isNew: true,
      rating: 4.7,
    ),
    Product(
      id: 'p4',
      name: 'Collier Lune',
      description:
          'Collier plaqué or avec pendentif croissant de lune. Chaîne ajustable.',
      price: 75,
      categoryId: 'accessories',
      imageUrl:
          'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=450&q=70',
      isFeatured: true,
      rating: 4.9,
    ),
    Product(
      id: 'p5',
      name: 'Crème Velours',
      description:
          'Crème corps nourrissante au beurre de karité et notes de musc blanc.',
      price: 36,
      categoryId: 'beauty',
      imageUrl:
          'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=450&q=70',
      rating: 4.6,
    ),
    Product(
      id: 'p6',
      name: 'Écharpe Cachemire',
      description:
          'Écharpe 100 % cachemire, teinte taupe. Douceur absolue pour l’hiver.',
      price: 120,
      categoryId: 'fashion',
      imageUrl:
          'https://images.unsplash.com/photo-1601925260368-ae2f83cf8b7f?w=450&q=70',
      isNew: true,
      rating: 4.8,
    ),
    Product(
      id: 'p7',
      name: 'Vase Céramique',
      description:
          'Vase artisanal en céramique mate, tons beige et brun. Pièce unique.',
      price: 58,
      categoryId: 'home',
      imageUrl:
          'https://images.unsplash.com/photo-1578500494198-246f612d3b3d?w=450&q=70',
      isFeatured: true,
      rating: 4.7,
    ),
    Product(
      id: 'p8',
      name: 'Montre Minimal',
      description:
          'Montre bracelet cuir cognac, cadran champagne. Design épuré.',
      price: 210,
      categoryId: 'accessories',
      imageUrl:
          'https://images.unsplash.com/photo-1524592094714-0f0654e20314?w=450&q=70',
      rating: 4.9,
    ),
    Product(
      id: 'p9',
      name: 'Huile Capillaire',
      description:
          'Huile légère argan & camélia pour des cheveux brillants sans effet gras.',
      price: 42,
      categoryId: 'beauty',
      imageUrl:
          'https://images.unsplash.com/photo-1608248543800-ba2635b1c1ce?w=450&q=70',
      rating: 4.5,
    ),
    Product(
      id: 'p10',
      name: 'Blazer Lin Beige',
      description:
          'Blazer en lin lavé, coupe droite. Idéal pour un look chic décontracté.',
      price: 165,
      categoryId: 'fashion',
      imageUrl:
          'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=450&q=70',
      isFeatured: true,
      rating: 4.8,
    ),
  ];

  static Product? byId(String id) {
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<Product> byCategory(String categoryId) =>
      products.where((p) => p.categoryId == categoryId).toList();

  static List<Product> get featured =>
      products.where((p) => p.isFeatured).toList();

  static List<Product> get news => products.where((p) => p.isNew).toList();

  static List<Product> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return products;
    return products
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q),
        )
        .toList();
  }
}
