<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import SoftImage from './SoftImage.vue'
import { formatMoney } from '../lib/format'
import type { Product } from '../lib/types'
import { useCart } from '../state/cart'
import { useFavorites } from '../state/favorites'

const props = defineProps<{ product: Product }>()
const router = useRouter()
const cart = useCart()
const favorites = useFavorites()

const liked = computed(() => favorites.isFavorite(props.product.id))
const ratingLabel = computed(() =>
  props.product.ratingsCount > 0 ? props.product.rating.toFixed(1) : '—',
)

function open() {
  router.push({ name: 'product', params: { id: props.product.id } })
}

function toggleFav(e: Event) {
  e.stopPropagation()
  favorites.toggle(props.product.id)
}

function addCart(e: Event) {
  e.stopPropagation()
  cart.add(props.product)
}
</script>

<template>
  <article class="card" @click="open">
    <div class="media">
      <SoftImage :url="product.imageUrl" :alt="product.name" />
      <div class="fade" />
      <span v-if="product.isNew" class="badge">NOUVEAU</span>
      <span class="rating">★ {{ ratingLabel }}</span>
      <button class="fav" type="button" @click="toggleFav" :aria-label="liked ? 'Retirer des favoris' : 'Ajouter aux favoris'">
        {{ liked ? '♥' : '♡' }}
      </button>
    </div>
    <div class="body">
      <h3>{{ product.name }}</h3>
      <div class="row">
        <strong>{{ formatMoney(product.price) }}</strong>
        <button class="add" type="button" @click="addCart" aria-label="Ajouter au panier">+</button>
      </div>
    </div>
  </article>
</template>

<style scoped>
.card {
  background: var(--kv-surface);
  border-radius: var(--kv-radius);
  border: 1px solid rgba(197, 160, 128, 0.16);
  box-shadow: var(--kv-shadow);
  overflow: hidden;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  transition: transform 0.2s ease;
}
.card:hover {
  transform: translateY(-2px);
}
.media {
  position: relative;
  aspect-ratio: 1 / 1.05;
  background: var(--kv-surface-muted);
}
.fade {
  position: absolute;
  inset: 0;
  background: linear-gradient(to bottom, transparent 70%, rgba(0, 0, 0, 0.08));
  pointer-events: none;
}
.badge {
  position: absolute;
  left: 8px;
  top: 8px;
  background: linear-gradient(135deg, #d4af37, #c5a080);
  color: var(--kv-brown);
  font-size: 0.58rem;
  font-weight: 800;
  letter-spacing: 0.08em;
  padding: 0.28rem 0.45rem;
  border-radius: 8px;
}
.rating {
  position: absolute;
  left: 8px;
  bottom: 8px;
  background: rgba(27, 17, 11, 0.72);
  color: var(--kv-cream);
  font-size: 0.65rem;
  font-weight: 700;
  padding: 0.2rem 0.45rem;
  border-radius: 999px;
  border: 1px solid rgba(197, 160, 128, 0.55);
}
.fav {
  position: absolute;
  right: 8px;
  top: 8px;
  width: 32px;
  height: 32px;
  border-radius: 999px;
  border: none;
  background: rgba(253, 251, 247, 0.92);
  color: var(--kv-brown);
  cursor: pointer;
  font-size: 1rem;
}
.body {
  padding: 0.75rem 0.8rem 0.9rem;
}
.body h3 {
  margin: 0 0 0.55rem;
  font-size: 0.86rem;
  font-weight: 600;
  line-height: 1.25;
  min-height: 2.2em;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
.row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.5rem;
}
.row strong {
  color: var(--kv-brown);
  font-size: 0.82rem;
}
.add {
  width: 30px;
  height: 30px;
  border-radius: 10px;
  border: none;
  background: linear-gradient(135deg, #3e2723, #251614);
  color: var(--kv-gold-light);
  font-size: 1.1rem;
  cursor: pointer;
}
</style>
