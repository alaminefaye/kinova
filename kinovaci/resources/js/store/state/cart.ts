import { computed, reactive } from 'vue'
import { api } from '../api/client'
import type { CartItem, Product } from '../lib/types'

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

export function useCart() {
  const itemCount = computed(() => state.items.reduce((s, i) => s + i.quantity, 0))
  const subtotal = computed(() =>
    state.items.reduce((s, i) => s + getProductEffectivePrice(i.product) * i.quantity, 0),
  )
  const shipping = computed(() => {
    if (!state.items.length) return 0
    return subtotal.value >= 50000 ? 0 : 2500
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
    if (idx >= 0) state.items[idx].quantity += quantity
    else
      state.items.push({
        product,
        quantity,
        selectedSize: selectedSize ?? null,
        selectedColor: selectedColor ?? null,
      })
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
      state.items[index].quantity = quantity
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
    address: string
    city: string
    payment_method: 'card' | 'cod'
    notes?: string
  }) {
    const res = await api<{ data: any }>('/orders', {
      method: 'POST',
      json: {
        ...payload,
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
    total,
    add,
    remove,
    removeById,
    setQuantity,
    clear,
    placeOrder,
  }
}
