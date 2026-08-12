import { computed, reactive } from 'vue'
import { api, getToken } from '../api/client'

const LOCAL_KEY = 'kinova_favorites'

const state = reactive({
  ids: [] as string[],
})

function persistLocal() {
  localStorage.setItem(LOCAL_KEY, JSON.stringify(state.ids))
}

function hydrateLocal() {
  try {
    const raw = localStorage.getItem(LOCAL_KEY)
    if (!raw) return
    const parsed = JSON.parse(raw)
    if (Array.isArray(parsed)) state.ids = parsed.map(String)
  } catch {
    /* ignore */
  }
}

hydrateLocal()

export function useFavorites() {
  const count = computed(() => state.ids.length)

  function isFavorite(id: string) {
    return state.ids.includes(String(id))
  }

  async function loadFromApi() {
    if (!getToken()) return
    const res = await api<{ data: any[] }>('/customer/favorites')
    const ids = (res.data || []).map((p) => String(p.id ?? p.product_id))
    state.ids = ids
    persistLocal()
  }

  async function toggle(productId: string) {
    const id = String(productId)
    if (isFavorite(id)) {
      state.ids = state.ids.filter((x) => x !== id)
      persistLocal()
      if (getToken()) {
        try {
          await api(`/customer/favorites/${id}`, { method: 'DELETE' })
        } catch {
          /* keep local */
        }
      }
      return
    }

    state.ids = [...state.ids, id]
    persistLocal()
    if (getToken()) {
      try {
        await api('/customer/favorites', {
          method: 'POST',
          json: { product_id: Number(id) },
        })
      } catch {
        /* keep local */
      }
    }
  }

  async function sync() {
    if (!getToken() || !state.ids.length) return
    try {
      await api('/customer/favorites/sync', {
        method: 'POST',
        json: { product_ids: state.ids.map(Number) },
      })
    } catch {
      /* ignore */
    }
  }

  return { state, count, isFavorite, loadFromApi, toggle, sync }
}
