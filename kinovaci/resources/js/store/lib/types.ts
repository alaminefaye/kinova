export type Category = {
  id: string
  name: string
  imageUrl: string
  slug: string
}

export type HeroSlide = {
  id: string
  title: string
  imageUrl: string
  tag: string
  ctaLabel: string
  linkType: string
  linkValue?: string | null
}

export type ProductSize = {
  name: string
  stock: number
}

export type ProductColor = {
  name: string
  hex?: string
  stock: number
}

export type Product = {
  id: string
  name: string
  description: string
  price: number
  promoPrice?: number | null
  categoryId: string
  imageUrl: string
  images: string[]
  sizes: ProductSize[]
  colors: ProductColor[]
  stock: number
  rating: number
  ratingsCount: number
  isNew: boolean
  isFeatured: boolean
}

export type CartItem = {
  product: Product
  quantity: number
  selectedSize?: string | null
  selectedColor?: string | null
}

export type UserProfile = {
  id: number
  name: string
  email?: string | null
  phone?: string | null
  address?: string | null
  city?: string | null
  avatar_url?: string | null
  vip?: boolean
  vip_tier?: string
  loyalty_points?: number
}

export type OrderSummary = {
  reference: string
  total: number
  status: string
  created_at: string
  tracking_number?: string | null
  carrier?: string | null
}

export function mapCategory(json: any): Category {
  return {
    id: String(json.id),
    name: String(json.name ?? ''),
    imageUrl: String(json.image_url ?? ''),
    slug: String(json.slug ?? ''),
  }
}

export function mapHero(json: any): HeroSlide {
  return {
    id: String(json.id),
    title: String(json.title ?? ''),
    imageUrl: String(json.image_url ?? ''),
    tag: String(json.tag ?? ''),
    ctaLabel: String(json.cta_label ?? 'DÉCOUVRIR'),
    linkType: String(json.link_type ?? 'catalog'),
    linkValue: json.link_value != null ? String(json.link_value) : null,
  }
}

export function mapProduct(json: any): Product {
  const gallery: string[] = []
  if (Array.isArray(json.gallery)) {
    for (const item of json.gallery) {
      if (item) gallery.push(String(item))
    }
  }
  const imageUrl = String(json.image_url ?? (gallery[0] ?? ''))
  const promoPrice =
    json.promo_price != null && Number(json.promo_price) > 0 ? Number(json.promo_price) : null

  const sizes: ProductSize[] = []
  if (Array.isArray(json.sizes)) {
    for (const s of json.sizes) {
      if (s && s.name) {
        sizes.push({
          name: String(s.name),
          stock: Number(s.stock ?? 0),
        })
      }
    }
  }

  const colors: ProductColor[] = []
  if (Array.isArray(json.colors)) {
    for (const c of json.colors) {
      if (c && c.name) {
        colors.push({
          name: String(c.name),
          hex: c.hex ? String(c.hex) : undefined,
          stock: Number(c.stock ?? 0),
        })
      }
    }
  }

  return {
    id: String(json.id),
    name: String(json.name ?? ''),
    description: String(json.description ?? ''),
    price: Number(json.price ?? 0),
    promoPrice,
    categoryId: String(json.category_id ?? ''),
    imageUrl,
    images: gallery.length ? gallery : imageUrl ? [imageUrl] : [],
    sizes,
    colors,
    stock: Number(json.stock ?? 0),
    rating: Number(json.rating ?? 0),
    ratingsCount: Number(json.ratings_count ?? 0),
    isNew: json.is_new === true || json.is_new === 1,
    isFeatured: json.is_featured === true || json.is_featured === 1,
  }
}
