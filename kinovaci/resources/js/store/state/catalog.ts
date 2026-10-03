import { computed, reactive } from 'vue'
import { api } from '../api/client'
import { mapCategory, mapHero, mapProduct, type Category, type HeroSlide, type Product } from '../lib/types'
import { syncCartWithCatalog } from './cart'

const state = reactive({
  categories: [] as Category[],
  products: [] as Product[],
  heroSlides: [] as HeroSlide[],
  loading: false,
  error: '' as string,
  loaded: false,
})

export function useCatalog() {
  const featured = computed(() => state.products.filter((p) => p.isFeatured))
  const news = computed(() => state.products.filter((p) => p.isNew))

  function byId(id: string) {
    return state.products.find((p) => p.id === String(id))
  }

  function byCategory(categoryId?: string | null) {
    if (!categoryId) return state.products
    return state.products.filter((p) => p.categoryId === String(categoryId))
  }

  function search(q: string) {
    const needle = q.trim().toLowerCase()
    if (!needle) return state.products
    return state.products.filter(
      (p) =>
        p.name.toLowerCase().includes(needle) ||
        p.description.toLowerCase().includes(needle),
    )
  }

  function patchRating(productId: string, average: number, count: number) {
    const p = byId(productId)
    if (!p) return
    p.rating = average
    p.ratingsCount = count
  }

  /** L'API pagine les produits : on récupère toutes les pages. */
  async function fetchAllProducts(): Promise<any[]> {
    const all: any[] = []
    let page = 1
    let lastPage = 1
    do {
      const res = await api<{ data: any[]; last_page?: number }>(`/products?per_page=200&page=${page}`)
      all.push(...(res.data || []))
      lastPage = Number(res.last_page ?? 1)
      page++
    } while (page <= lastPage && page <= 25)
    return all
  }

  async function load() {
    state.loading = true
    state.error = ''
    try {
      const [cats, prods, heroes] = await Promise.all([
        api<{ data: any[] }>('/categories'),
        fetchAllProducts(),
        api<{ data: any[] }>('/hero-slides'),
      ])
      state.categories = (cats.data || []).map(mapCategory)
      state.products = prods.map(mapProduct)
      state.heroSlides = (heroes.data || []).map(mapHero)
      state.loaded = true
      syncCartWithCatalog(byId)
    } catch (e: any) {
      state.error = e?.message || 'Impossible de charger le catalogue'
    } finally {
      state.loading = false
    }
  }

  return {
    state,
    featured,
    news,
    byId,
    byCategory,
    search,
    patchRating,
    load,
  }
}
