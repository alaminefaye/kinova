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
      price: 28500,
      promoPrice: 22500,
      categoryId: 'beauty',
      imageUrl:
          'https://images.unsplash.com/photo-1571781926291-c77df809e0b0?w=450&q=70',
      images: [
        'https://images.unsplash.com/photo-1571781926291-c77df809e0b0?w=450&q=70',
        'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=450&q=70',
      ],
      sizes: [
        ProductSize(name: '30 ml', stock: 20),
        ProductSize(name: '50 ml', stock: 15),
        ProductSize(name: '100 ml (Édition)', stock: 0),
      ],
      stock: 35,
      isNew: true,
      isFeatured: true,
      rating: 4.9,
    ),
    Product(
      id: 'p2',
      name: 'Sac Cuir Sable',
      description:
          'Sac en cuir grainé couleur sable, finitions or rose. Porté main ou bandoulière.',
      price: 89000,
      promoPrice: 69000,
      categoryId: 'fashion',
      imageUrl:
          'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=450&q=70',
      colors: [
        ProductColor(name: 'Sable Doré', hex: '#D4A373', stock: 8),
        ProductColor(name: 'Noir Intense', hex: '#1F2937', stock: 7),
        ProductColor(name: 'Cognac Vintage', hex: '#92400E', stock: 0),
      ],
      stock: 15,
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
      price: 78000,
      categoryId: 'fashion',
      imageUrl:
          'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=450&q=70',
      sizes: [
        ProductSize(name: '36 (XS)', stock: 0),
        ProductSize(name: '38 (S)', stock: 5),
        ProductSize(name: '40 (M)', stock: 8),
        ProductSize(name: '42 (L)', stock: 4),
        ProductSize(name: '44 (XL)', stock: 0),
      ],
      stock: 17,
      isFeatured: true,
      rating: 4.8,
    ),
    Product(
      id: 'p11',
      name: 'Rouge Velours KINOVA',
      description:
          'Rouge à lèvres mat velours, teinte terracotta signature. Tenue longue durée, confort non asséchant. Étui doré.',
      price: 14500,
      promoPrice: 11500,
      categoryId: 'beauty',
      imageUrl:
          'https://images.unsplash.com/photo-1586495777744-4413f21062fa?w=450&q=70',
      sizes: [
        ProductSize(name: 'Standard (3.5g)', stock: 30),
        ProductSize(name: 'Mini Format (1.5g)', stock: 0),
      ],
      colors: [
        ProductColor(name: 'Terracotta Signature', hex: '#C2410C', stock: 15),
        ProductColor(name: 'Rouge Carmin', hex: '#DC2626', stock: 10),
        ProductColor(name: 'Rose Poudré', hex: '#F472B6', stock: 0),
        ProductColor(name: 'Nude Chaud', hex: '#D97706', stock: 5),
      ],
      stock: 30,
      isFeatured: true,
      rating: 4.8,
      ratingsCount: 31,
    ),
    Product(
      id: 'p12',
      name: 'Brume Éclat Visage',
      description:
          'Brume hydratante vitamine C et eau de rose. Fixe le maquillage et ravive l’éclat en journée. Spray 100 ml.',
      price: 16000,
      categoryId: 'beauty',
      imageUrl:
          'https://images.unsplash.com/photo-1611930022073-b7a4ba5fcccd?w=450&q=70',
      stock: 0,
      rating: 4.6,
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
