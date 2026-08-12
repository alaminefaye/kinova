<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import SoftImage from '../components/SoftImage.vue'
import { api, getToken } from '../api/client'
import { formatMoney } from '../lib/format'
import { mapProduct, type Product } from '../lib/types'
import { useCatalog } from '../state/catalog'
import { useCart } from '../state/cart'
import { useFavorites } from '../state/favorites'

const route = useRoute()
const router = useRouter()
const catalog = useCatalog()
const cart = useCart()
const favorites = useFavorites()

const remote = ref<Product | null>(null)
const loading = ref(false)
const imageIndex = ref(0)
const qty = ref(1)
const average = ref(0)
const ratingsCount = ref(0)
const myRating = ref<number | null>(null)
const ratingLoading = ref(false)
const toast = ref('')

const product = computed(() => {
  return catalog.byId(String(route.params.id)) || remote.value
})

const gallery = computed(() => {
  const p = product.value
  if (!p) return []
  const imgs = p.images?.length ? p.images : p.imageUrl ? [p.imageUrl] : []
  return imgs
})

async function ensureProduct() {
  const id = String(route.params.id)
  if (catalog.byId(id)) {
    remote.value = null
    return
  }
  if (!catalog.state.loaded && !catalog.state.loading) {
    await catalog.load()
    if (catalog.byId(id)) return
  }
  loading.value = true
  try {
    const res = await api<{ data: any }>(`/products/${id}`)
    remote.value = mapProduct(res.data)
  } catch {
    remote.value = null
  } finally {
    loading.value = false
  }
}

async function loadRating() {
  const p = product.value
  if (!p) return
  average.value = p.rating
  ratingsCount.value = p.ratingsCount
  try {
    const path = getToken()
      ? `/customer/products/${p.id}/rating`
      : `/products/${p.id}/rating`
    const res = await api<{ data: any }>(path)
    average.value = Number(res.data.average ?? average.value)
    ratingsCount.value = Number(res.data.count ?? ratingsCount.value)
    myRating.value = res.data.my_rating != null ? Number(res.data.my_rating) : null
  } catch {
    /* keep */
  }
}

onMounted(async () => {
  await ensureProduct()
  await loadRating()
})

watch(
  () => route.params.id,
  async () => {
    imageIndex.value = 0
    qty.value = 1
    await ensureProduct()
    await loadRating()
  },
)

async function rate(stars: number) {
  if (!product.value) return
  if (!getToken()) {
    router.push({ name: 'auth', query: { redirect: route.fullPath } })
    return
  }
  ratingLoading.value = true
  myRating.value = stars
  try {
    const res = await api<{ data: any }>('/customer/ratings', {
      method: 'POST',
      json: { product_id: Number(product.value.id), stars },
    })
    average.value = Number(res.data.average ?? average.value)
    ratingsCount.value = Number(res.data.count ?? ratingsCount.value)
    myRating.value = Number(res.data.my_rating ?? stars)
    catalog.patchRating(product.value.id, average.value, ratingsCount.value)
    toast.value = 'Merci pour votre note !'
  } catch (e: any) {
    toast.value = e?.message || 'Impossible d’enregistrer la note'
  } finally {
    ratingLoading.value = false
    setTimeout(() => (toast.value = ''), 2200)
  }
}

function addToCart() {
  if (!product.value) return
  cart.add(product.value, qty.value)
  toast.value = qty.value > 1 ? `Ajouté ×${qty.value}` : 'Ajouté au panier'
  setTimeout(() => (toast.value = ''), 1800)
}
</script>

<template>
  <div v-if="loading" class="missing">Chargement…</div>

  <div v-else-if="product" class="page">
    <div class="media">
      <SoftImage :url="gallery[imageIndex] || product.imageUrl" :alt="product.name" />
      <button class="back" type="button" @click="router.back()">←</button>
      <button class="fav" type="button" @click="favorites.toggle(product.id)">
        {{ favorites.isFavorite(product.id) ? '♥' : '♡' }}
      </button>
      <div v-if="gallery.length > 1" class="dots">
        <button
          v-for="(img, i) in gallery"
          :key="img + i"
          type="button"
          :class="{ on: i === imageIndex }"
          @click="imageIndex = i"
        />
      </div>
    </div>

    <div class="kv-container body">
      <p class="price">{{ formatMoney(product.price) }}</p>
      <h1 class="kv-display">{{ product.name }}</h1>
      <p class="desc">{{ product.description }}</p>

      <div class="qty-row">
        <span>Quantité</span>
        <div class="qty">
          <button type="button" @click="qty = Math.max(1, qty - 1)">−</button>
          <strong>{{ qty }}</strong>
          <button type="button" @click="qty++">+</button>
        </div>
      </div>

      <section class="rating-box">
        <div class="rating-head">
          <strong>{{ ratingsCount > 0 ? average.toFixed(1) : '—' }}</strong>
          <span>{{ ratingsCount === 0 ? 'Aucune note' : `${ratingsCount} avis` }}</span>
        </div>
        <p>{{ myRating == null ? 'Notez cet article' : `Votre note : ${myRating}/5` }}</p>
        <div class="stars">
          <button
            v-for="star in 5"
            :key="star"
            type="button"
            :disabled="ratingLoading"
            @click="rate(star)"
          >
            {{ (myRating ?? 0) >= star ? '★' : '☆' }}
          </button>
        </div>
      </section>

      <button class="kv-btn kv-btn-dark full" type="button" @click="addToCart">
        Ajouter au panier
      </button>
    </div>

    <div v-if="toast" class="toast">{{ toast }}</div>
  </div>

  <div v-else class="kv-container missing">
    <p>Produit introuvable.</p>
    <RouterLink :to="{ name: 'catalog' }">Retour boutique</RouterLink>
  </div>
</template>

<style scoped>
.media {
  position: relative;
  height: min(70vw, 420px);
  background: var(--kv-surface-muted);
}
.back,
.fav {
  position: absolute;
  top: 1rem;
  width: 40px;
  height: 40px;
  border-radius: 999px;
  border: none;
  background: rgba(253, 251, 247, 0.92);
  cursor: pointer;
  font-size: 1.1rem;
  z-index: 2;
}
.back {
  left: 1rem;
}
.fav {
  right: 1rem;
}
.dots {
  position: absolute;
  left: 50%;
  bottom: 1rem;
  transform: translateX(-50%);
  display: flex;
  gap: 0.35rem;
  z-index: 2;
}
.dots button {
  width: 7px;
  height: 7px;
  border-radius: 999px;
  border: none;
  background: rgba(253, 251, 247, 0.4);
  padding: 0;
  cursor: pointer;
}
.dots button.on {
  width: 16px;
  background: var(--kv-gold);
}
.body {
  margin-top: -1.5rem;
  position: relative;
  background: var(--kv-bg);
  border-radius: 24px 24px 0 0;
  padding: 1.35rem 0 2rem;
}
.price {
  margin: 0;
  color: var(--kv-gold);
  font-weight: 800;
  letter-spacing: 0.04em;
}
.body h1 {
  margin: 0.35rem 0 0.75rem;
  font-size: 1.55rem;
}
.desc {
  color: var(--kv-muted);
  line-height: 1.55;
  font-size: 0.92rem;
}
.qty-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin: 1rem 0;
  color: var(--kv-muted);
  font-size: 0.85rem;
  font-weight: 700;
}
.qty {
  display: inline-flex;
  align-items: center;
  gap: 0.65rem;
  background: var(--kv-surface);
  border-radius: 999px;
  padding: 0.25rem 0.4rem;
  border: 1px solid rgba(197, 160, 128, 0.22);
}
.qty button {
  width: 30px;
  height: 30px;
  border: none;
  border-radius: 999px;
  background: var(--kv-brown);
  color: var(--kv-cream);
  cursor: pointer;
}
.rating-box {
  margin: 0.5rem 0 1.25rem;
  padding: 1rem;
  background: var(--kv-surface);
  border-radius: 18px;
  border: 1px solid rgba(197, 160, 128, 0.22);
  box-shadow: var(--kv-shadow);
}
.rating-head {
  display: flex;
  align-items: baseline;
  gap: 0.55rem;
}
.rating-head strong {
  font-family: var(--kv-font-display);
  font-size: 1.25rem;
}
.rating-head span,
.rating-box > p {
  color: var(--kv-muted);
  font-size: 0.8rem;
}
.stars {
  display: flex;
  gap: 0.25rem;
  margin-top: 0.45rem;
}
.stars button {
  border: none;
  background: transparent;
  color: var(--kv-gold-rich);
  font-size: 1.7rem;
  cursor: pointer;
  padding: 0;
}
.full {
  width: 100%;
}
.toast {
  position: fixed;
  left: 50%;
  bottom: 1.5rem;
  transform: translateX(-50%);
  background: var(--kv-brown);
  color: var(--kv-cream);
  padding: 0.7rem 1rem;
  border-radius: 999px;
  font-size: 0.8rem;
  z-index: 60;
}
.missing {
  padding: 3rem 0;
  text-align: center;
  color: var(--kv-muted);
}
</style>
