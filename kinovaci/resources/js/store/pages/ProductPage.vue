<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import SoftImage from '../components/SoftImage.vue'
import { api, getToken } from '../api/client'
import { formatMoney } from '../lib/format'
import { useCatalog } from '../state/catalog'
import { useCart } from '../state/cart'
import { useFavorites } from '../state/favorites'

const route = useRoute()
const router = useRouter()
const catalog = useCatalog()
const cart = useCart()
const favorites = useFavorites()

const product = computed(() => catalog.byId(String(route.params.id)))
const average = ref(0)
const ratingsCount = ref(0)
const myRating = ref<number | null>(null)
const ratingLoading = ref(false)
const toast = ref('')

onMounted(async () => {
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
    /* keep defaults */
  }
})

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
  cart.add(product.value)
  toast.value = 'Ajouté au panier'
  setTimeout(() => (toast.value = ''), 1800)
}
</script>

<template>
  <div v-if="product" class="page">
    <div class="media">
      <SoftImage :url="product.imageUrl" :alt="product.name" />
      <button class="back" type="button" @click="router.back()">←</button>
      <button class="fav" type="button" @click="favorites.toggle(product.id)">
        {{ favorites.isFavorite(product.id) ? '♥' : '♡' }}
      </button>
    </div>

    <div class="kv-container body">
      <p class="price">{{ formatMoney(product.price) }}</p>
      <h1 class="kv-display">{{ product.name }}</h1>
      <p class="desc">{{ product.description }}</p>

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
}
.back {
  left: 1rem;
}
.fav {
  right: 1rem;
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
.rating-box {
  margin: 1.25rem 0;
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
  bottom: 5.5rem;
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
}
</style>
