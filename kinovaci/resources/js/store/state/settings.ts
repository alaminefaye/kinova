import { reactive } from 'vue'
import { api } from '../api/client'

export type StoreSettings = {
  shipping: {
    mode: 'courier' | 'fixed'
    note: string
    fee: number
    free_enabled: boolean
    free_threshold: number
  }
  loyalty: {
    amount_per_step: number
    points_per_step: number
    tiers: { silver: number; gold: number; vip: number }
  }
  sections: Record<
    'hero' | 'promo_banner' | 'categories' | 'featured' | 'vip_banner' | 'perks' | 'news',
    boolean
  >
  texts: {
    promo_banner: string
    vip_title: string
    vip_subtitle: string
    perks: { title: string; subtitle: string }[]
    categories_title: string
    featured_title: string
    news_title: string
  }
  profile: {
    show_loyalty: boolean
    show_tier_badge: boolean
    show_next_tier: boolean
    loyalty_title: string
    loyalty_rule: string
  }
}

const state = reactive<{ data: StoreSettings; loaded: boolean }>({
  loaded: false,
  data: {
    shipping: {
      mode: 'courier',
      note: 'Livraison optionnelle. Les frais sont à régler directement au livreur selon votre zone.',
      fee: 2500,
      free_enabled: true,
      free_threshold: 50000,
    },
    loyalty: { amount_per_step: 10000, points_per_step: 1, tiers: { silver: 20, gold: 50, vip: 100 } },
    sections: {
      hero: true,
      promo_banner: true,
      categories: true,
      featured: true,
      vip_banner: true,
      perks: true,
      news: true,
    },
    texts: {
      promo_banner: 'PAIEMENT À LA LIVRAISON · RETOURS 14 JOURS',
      vip_title: 'Rejoignez le Cercle VIP',
      vip_subtitle: '10 000 FCFA dépensés = 1 point. Avantages exclusifs.',
      perks: [
        { title: 'Livraison à domicile', subtitle: 'Paiement à la réception' },
        { title: 'Soins Naturels', subtitle: 'Formules pures' },
        { title: 'Garantie KINOVA', subtitle: 'Satisfait ou remboursé' },
      ],
      categories_title: 'Nos Univers',
      featured_title: 'Sélection',
      news_title: 'Nouveautés',
    },
    profile: {
      show_loyalty: true,
      show_tier_badge: true,
      show_next_tier: true,
      loyalty_title: 'FIDÉLITÉ KINOVA',
      loyalty_rule: '10 000 FCFA dépensés = 1 point',
    },
  },
})

let pending: Promise<void> | null = null

async function load() {
  if (pending) return pending
  pending = api<{ data: StoreSettings }>('/settings')
    .then((res) => {
      if (res?.data) state.data = res.data
      state.loaded = true
    })
    .catch(() => {
      /* garde les valeurs par défaut */
    })
    .finally(() => {
      pending = null
    })
  return pending
}

export function shippingFor(subtotal: number, isDelivery = true): number {
  const s = state.data.shipping
  if (!isDelivery || s.mode !== 'fixed') return 0
  if (s.free_enabled && subtotal >= s.free_threshold) return 0
  return s.fee
}

export function nextTierHint(points: number): string | null {
  const t = state.data.loyalty.tiers
  const steps: [number, string][] = [
    [t.silver, 'ARGENT'],
    [t.gold, 'OR'],
    [t.vip, 'VIP'],
  ]
  for (const [threshold, label] of steps) {
    if (points < threshold) {
      const missing = threshold - points
      return `Plus que ${missing} point${missing > 1 ? 's' : ''} pour ${label}`
    }
  }
  return null
}

export function useSettings() {
  if (!state.loaded) void load()
  return { state, load }
}
