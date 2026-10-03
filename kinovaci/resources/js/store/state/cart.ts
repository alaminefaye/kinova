import { computed, reactive } from 'vue'
import { api } from '../api/client'
import type { CartItem, Product } from '../lib/types'
import { shippingFor, useSettings } from './settings'

const CART_KEY = 'kinova_cart'

type StoredLine = {
  product: Product
  quantity: number
  selectedSize?: string | null
  selectedColor?: string | null
}

const state = reactive({
  items: [] as CartItem[],
})

function persist() {
  localStorage.setItem(CART_KEY, JSON.stringify(state.items))
}

function hydrate() {
  try {
    const raw = localStorage.getItem(CART_KEY)
    if (!raw) return
    const parsed = JSON.parse(raw) as StoredLine[]
    if (Array.isArray(parsed)) {
      state.items = parsed.map((i) => ({
        product: i.product,
        quantity: i.quantity,
        selectedSize: i.selectedSize ?? null,
        selectedColor: i.selectedColor ?? null,
      }))
    }
  } catch {
    /* ignore */
  }
}

hydrate()

export function getProductEffectivePrice(product: Product): number {
  if (product.promoPrice != null && product.promoPrice > 0 && product.promoPrice < product.price) {
    return product.promoPrice
  }
  return product.price
}

/** Quantité maximale commandable (stock produit, taille et couleur choisies). */
export function maxQuantity(
  product: Product,
  selectedSize?: string | null,
  selectedColor?: string | null,
): number {
  let max = Number(product.stock ?? 0)
  const size = product.sizes?.find((s) => s.name === selectedSize)
  if (size && size.stock < max) max = size.stock
  const color = product.colors?.find((c) => c.name === selectedColor)
  if (color && color.stock < max) max = color.stock
  return Math.max(0, Math.min(max, 999))
}

function clampQuantity(item: CartItem, quantity: number) {
  const max = maxQuantity(item.product, item.selectedSize, item.selectedColor)
  return Math.max(1, Math.min(quantity, Math.max(max, 1)))
}

/** Met à jour prix / stock du panier avec le catalogue frais et retire les produits indisponibles. */
export function syncCartWithCatalog(byId: (id: string) => Product | undefined) {
  if (!state.items.length) return
  state.items = state.items
    .map((item) => {
      const fresh = byId(item.product.id)
      if (!fresh) return null
      const next = { ...item, product: fresh }
      next.quantity = clampQuantity(next, next.quantity)
      return next
    })
    .filter((i): i is CartItem => i !== null)
  persist()
}

export function useCart() {
  const itemCount = computed(() => state.items.reduce((s, i) => s + i.quantity, 0))
  const subtotal = computed(() =>
    state.items.reduce((s, i) => s + getProductEffectivePrice(i.product) * i.quantity, 0),
  )
  const settings = useSettings()
  const shippingToCourier = computed(() => settings.state.data.shipping.mode !== 'fixed')
  const shipping = computed(() => {
    if (!state.items.length) return 0
    return shippingFor(subtotal.value)
  })
  const total = computed(() => subtotal.value + shipping.value)

  function add(
    product: Product,
    quantity = 1,
    selectedSize?: string | null,
    selectedColor?: string | null,
  ) {
    const idx = state.items.findIndex(
      (i) =>
        i.product.id === product.id &&
        (i.selectedSize ?? null) === (selectedSize ?? null) &&
        (i.selectedColor ?? null) === (selectedColor ?? null),
    )
    if (idx >= 0) {
      const item = state.items[idx]
      item.quantity = clampQuantity(item, item.quantity + quantity)
    } else {
      const item: CartItem = {
        product,
        quantity,
        selectedSize: selectedSize ?? null,
        selectedColor: selectedColor ?? null,
      }
      item.quantity = clampQuantity(item, quantity)
      state.items.push(item)
    }
    persist()
  }

  function remove(index: number) {
    if (index >= 0 && index < state.items.length) {
      state.items.splice(index, 1)
      persist()
    }
  }

  function removeById(productId: string) {
    state.items = state.items.filter((i) => i.product.id !== productId)
    persist()
  }

  function setQuantity(index: number, quantity: number) {
    if (quantity <= 0) {
      remove(index)
      return
    }
    if (state.items[index]) {
      state.items[index].quantity = clampQuantity(state.items[index], quantity)
      persist()
    }
  }

  function clear() {
    state.items = []
    persist()
  }

  async function placeOrder(payload: {
    customer_name: string
    customer_phone: string
    customer_email?: string
    is_delivery: boolean
    address: string
    city: string
    latitude?: number | null
    longitude?: number | null
    delivery_details?: string
    notes?: string
  }) {
    const res = await api<{ data: any }>('/orders', {
      method: 'POST',
      json: {
        ...payload,
        payment_method: 'cod',
        items: state.items.map((i) => ({
          product_id: Number(i.product.id),
          quantity: i.quantity,
          selected_size: i.selectedSize ?? null,
          selected_color: i.selectedColor ?? null,
        })),
      },
    })
    clear()
    return res.data
  }

  return {
    state,
    itemCount,
    subtotal,
    shipping,
    shippingToCourier,
    total,
    add,
    remove,
    removeById,
    setQuantity,
    clear,
    placeOrder,
  }
}
