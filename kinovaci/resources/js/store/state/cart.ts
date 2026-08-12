import { computed, reactive } from 'vue'
import { api } from '../api/client'
import type { CartItem, Product } from '../lib/types'

const CART_KEY = 'kinova_cart'

type StoredLine = { product: Product; quantity: number }

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
      state.items = parsed.map((i) => ({ product: i.product, quantity: i.quantity }))
    }
  } catch {
    /* ignore */
  }
}

hydrate()

export function useCart() {
  const itemCount = computed(() => state.items.reduce((s, i) => s + i.quantity, 0))
  const subtotal = computed(() =>
    state.items.reduce((s, i) => s + i.product.price * i.quantity, 0),
  )
  const shipping = computed(() => {
    if (!state.items.length) return 0
    return subtotal.value >= 100 ? 0 : 6.5
  })
  const total = computed(() => subtotal.value + shipping.value)

  function add(product: Product, quantity = 1) {
    const idx = state.items.findIndex((i) => i.product.id === product.id)
    if (idx >= 0) state.items[idx].quantity += quantity
    else state.items.push({ product, quantity })
    persist()
  }

  function remove(productId: string) {
    state.items = state.items.filter((i) => i.product.id !== productId)
    persist()
  }

  function setQuantity(productId: string, quantity: number) {
    if (quantity <= 0) {
      remove(productId)
      return
    }
    const item = state.items.find((i) => i.product.id === productId)
    if (item) {
      item.quantity = quantity
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
    setQuantity,
    clear,
    placeOrder,
  }
}
