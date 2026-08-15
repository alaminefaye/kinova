<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import SoftImage from '../components/SoftImage.vue'
import KinovaLoader from '../components/KinovaLoader.vue'
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

const selectedSize = ref<string | null>(null)
const selectedColor = ref<string | null>(null)

const product = computed(() => {
  return catalog.byId(String(route.params.id)) || remote.value
})

const gallery = computed(() => {
  const p = product.value
  if (!p) return []
  const imgs = p.images?.length ? p.images : p.imageUrl ? [p.imageUrl] : []
  return imgs
})

const hasPromo = computed(() => {
  const p = product.value
  return Boolean(p && p.promoPrice != null && p.promoPrice > 0 && p.promoPrice < p.price)
})

const discountPercent = computed(() => {
  const p = product.value
  if (!p || !hasPromo.value) return 0
  return Math.round(((p.price - (p.promoPrice ?? 0)) / p.price) * 100)
})

const availableSizes = computed(() => {
  return product.value?.sizes?.filter((s) => s.stock > 0) ?? []
})

const availableColors = computed(() => {
  return product.value?.colors?.filter((c) => c.stock > 0) ?? []
})

const isOutOfStock = computed(() => {
  const p = product.value
  if (!p) return false
  if (p.stock <= 0) return true
  if (p.sizes?.length && availableSizes.value.length === 0) return true
  if (p.colors?.length && availableColors.value.length === 0) return true
  return false
})

watch(
  product,
  (p) => {
    if (p) {
      if (availableSizes.value.length > 0) {
        selectedSize.value = availableSizes.value[0].name
      } else {
        selectedSize.value = null
      }
      if (availableColors.value.length > 0) {
        selectedColor.value = availableColors.value[0].name
      } else {
        selectedColor.value = null
      }
    }
  },
  { immediate: true },
)

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
  if (!product.value || isOutOfStock.value) return
  cart.add(product.value, qty.value, selectedSize.value, selectedColor.value)
  toast.value = qty.value > 1 ? `Ajouté ×${qty.value}` : 'Ajouté au panier'
  setTimeout(() => (toast.value = ''), 1800)
}
</script>

<template>
  <div v-if="loading" class="missing">
    <KinovaLoader compact message="Chargement" :size="64" />
  </div>

  <div v-else-if="product" class="page">
    <div class="media">
      <SoftImage :url="gallery[imageIndex] || product.imageUrl" :alt="product.name" />
      <button class="back" type="button" @click="router.back()">←</button>
      <button class="fav" type="button" @click="favorites.toggle(product.id)">
        {{ favorites.isFavorite(product.id) ? '♥' : '♡' }}
      </button>

      <!-- Badge Rupture / Promo / Nouveau -->
      <span v-if="isOutOfStock" class="media-badge out-badge">RUPTURE DE STOCK</span>
      <span v-else-if="hasPromo" class="media-badge promo-badge">
        <span class="promo-pulse" />
        <span class="promo-text">OFFRE SPÉCIALE {{ discountPercent > 0 ? `-${discountPercent}%` : '' }}</span>
      </span>
      <span v-else-if="product.isNew" class="media-badge new-badge">NOUVEAU</span>

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
      <div v-if="hasPromo" class="price-container">
        <div class="price-row">
          <span class="old-price">{{ formatMoney(product.price) }}</span>
          <span class="price promo-price-val">{{ formatMoney(product.promoPrice!) }}</span>
          <span class="discount-pill">-{{ discountPercent }}%</span>
        </div>
      </div>
      <p v-else class="price">{{ formatMoney(product.price) }}</p>
      
      <h1 class="kv-display">{{ product.name }}</h1>
      <p class="desc">{{ product.description }}</p>

      <!-- Sélecteur de Tailles / Formats Dynamique -->
      <div v-if="availableSizes.length > 0" class="options-section">
        <div class="options-label">
          <span>Taille / Format</span>
          <strong v-if="selectedSize">{{ selectedSize }}</strong>
        </div>
        <div class="options-grid">
          <button
            v-for="s in availableSizes"
            :key="s.name"
            type="button"
            class="option-pill"
            :class="{ active: selectedSize === s.name }"
            @click="selectedSize = s.name"
          >
            {{ s.name }}
          </button>
        </div>
      </div>

      <!-- Sélecteur de Couleurs Dynamique -->
      <div v-if="availableColors.length > 0" class="options-section">
        <div class="options-label">
          <span>Couleur</span>
          <strong v-if="selectedColor">{{ selectedColor }}</strong>
        </div>
        <div class="colors-grid">
          <button
            v-for="c in availableColors"
            :key="c.name"
            type="button"
            class="color-pill"
            :class="{ active: selectedColor === c.name }"
            @click="selectedColor = c.name"
          >
            <span
              class="color-dot"
              :style="{ backgroundColor: c.hex || '#c5a080' }"
            />
            <span>{{ c.name }}</span>
          </button>
        </div>
      </div>

      <!-- Quantité & Rupture de stock -->
      <div v-if="!isOutOfStock" class="qty-row">
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

      <button
        v-if="!isOutOfStock"
        class="kv-btn kv-btn-dark full"
        type="button"
        @click="addToCart"
      >
        Ajouter au panier
      </button>
      <button
        v-else
        class="kv-btn full disabled-btn"
        type="button"
        disabled
      >
        Article Épuisé
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
.media-badge {
  position: absolute;
  left: 1rem;
  bottom: 2.2rem;
  font-size: 0.65rem;
  font-weight: 800;
  letter-spacing: 0.08em;
  padding: 0.35rem 0.65rem;
  border-radius: 999px;
  z-index: 2;
  display: inline-flex;
  align-items: center;
  gap: 5px;
}
.new-badge {
  background: linear-gradient(135deg, #d4af37, #c5a080);
  color: var(--kv-brown);
}
.out-badge {
  background: #64748b;
  color: #fff;
}
.promo-badge {
  background: linear-gradient(135deg, #b91c1c, #dc2626, #ea580c);
  color: #fff;
  box-shadow: 0 3px 12px rgba(220, 38, 38, 0.4);
  animation: promoFloat 2.8s ease-in-out infinite alternate;
}
.promo-pulse {
  display: inline-block;
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background-color: #ffffff;
  box-shadow: 0 0 6px #ffffff;
  animation: promoPulseDot 1.4s infinite ease-in-out;
}
.promo-text {
  position: relative;
  z-index: 1;
}
@keyframes promoFloat {
  0% {
    transform: scale(1);
  }
  50% {
    transform: scale(1.04);
    box-shadow: 0 4px 16px rgba(220, 38, 38, 0.6);
  }
  100% {
    transform: scale(1);
  }
}
@keyframes promoPulseDot {
  0%, 100% {
    opacity: 1;
    transform: scale(1);
  }
  50% {
    opacity: 0.4;
    transform: scale(1.4);
  }
}
.price-container {
  margin-bottom: 0.25rem;
}
.price-row {
  display: inline-flex;
  align-items: baseline;
  gap: 0.6rem;
}
.old-price {
  font-size: 0.95rem;
  color: #9e8e82;
  text-decoration: line-through;
  font-weight: 500;
}
.promo-price-val {
  color: #b91c1c !important;
  font-size: 1.25rem;
  font-weight: 800;
}
.discount-pill {
  background: rgba(185, 28, 28, 0.12);
  color: #b91c1c;
  font-size: 0.72rem;
  font-weight: 800;
  padding: 0.15rem 0.45rem;
  border-radius: 6px;
  border: 1px solid rgba(185, 28, 28, 0.25);
}
.price {
  margin: 0;
  color: var(--kv-gold);
  font-weight: 800;
  letter-spacing: 0.04em;
  font-size: 1.15rem;
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
.options-section {
  margin: 1.1rem 0;
}
.options-label {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.85rem;
  color: var(--kv-muted);
  font-weight: 600;
  margin-bottom: 0.6rem;
}
.options-label strong {
  color: var(--kv-brown);
  font-weight: 700;
}
.options-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}
.option-pill {
  border: 1px solid rgba(197, 160, 128, 0.35);
  background: var(--kv-surface);
  color: var(--kv-brown);
  padding: 0.45rem 0.9rem;
  border-radius: 999px;
  font-size: 0.82rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
}
.option-pill:hover {
  border-color: var(--kv-gold);
}
.option-pill.active {
  background: var(--kv-brown);
  color: var(--kv-cream);
  border-color: var(--kv-brown);
  box-shadow: 0 2px 8px rgba(37, 22, 20, 0.25);
}
.colors-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}
.color-pill {
  display: inline-flex;
  align-items: center;
  gap: 0.45rem;
  border: 1px solid rgba(197, 160, 128, 0.35);
  background: var(--kv-surface);
  color: var(--kv-brown);
  padding: 0.4rem 0.75rem;
  border-radius: 999px;
  font-size: 0.82rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
}
.color-pill:hover {
  border-color: var(--kv-gold);
}
.color-pill.active {
  background: var(--kv-brown);
  color: var(--kv-cream);
  border-color: var(--kv-brown);
  box-shadow: 0 2px 8px rgba(37, 22, 20, 0.25);
}
.color-dot {
  width: 14px;
  height: 14px;
  border-radius: 50%;
  border: 1px solid rgba(255, 255, 255, 0.6);
  box-shadow: 0 0 3px rgba(0, 0, 0, 0.2);
}
.disabled-btn {
  background: #cbd5e1 !important;
  color: #64748b !important;
  cursor: not-allowed !important;
  box-shadow: none !important;
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
