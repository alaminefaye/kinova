<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import ProductCard from '../components/ProductCard.vue'
import { api, getToken } from '../api/client'
import { mapProduct, type Product } from '../lib/types'
import { useCatalog } from '../state/catalog'
import { useFavorites } from '../state/favorites'

const router = useRouter()
const catalog = useCatalog()
const favorites = useFavorites()
const loading = ref(false)
const remoteProducts = ref<Product[]>([])

const products = computed(() => {
  const ids = new Set(favorites.state.ids.map(String))
  const fromCatalog = catalog.state.products.filter((p) => ids.has(p.id))
  const foundIds = new Set(fromCatalog.map((p) => p.id))
  const extras = remoteProducts.value.filter((p) => ids.has(p.id) && !foundIds.has(p.id))
  return [...fromCatalog, ...extras]
})

onMounted(async () => {
  loading.value = true
  try {
    if (getToken()) {
      await favorites.loadFromApi()
      const res = await api<{ data: any[] }>('/customer/favorites')
      remoteProducts.value = (res.data || []).map(mapProduct)
    }
  } catch {
    /* local favorites still shown */
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div class="page kv-container">
    <div class="kv-section-title">
      <h2>Favoris</h2>
      <span class="count">{{ products.length }}</span>
    </div>

    <p v-if="loading" class="muted">Chargement…</p>

    <div v-else-if="products.length" class="kv-grid-products">
      <ProductCard v-for="p in products" :key="p.id" :product="p" />
    </div>

    <div v-else class="empty">
      <div class="heart">♡</div>
      <h3 class="kv-display">Aucun favori</h3>
      <p>Ajoutez des articles depuis la boutique en touchant le cœur.</p>
      <button class="kv-btn kv-btn-primary" type="button" @click="router.push({ name: 'catalog' })">
        Explorer la boutique
      </button>
    </div>
  </div>
</template>

<style scoped>
.page {
  padding: 1.1rem 0 2rem;
}
.count {
  min-width: 1.5rem;
  height: 1.5rem;
  padding: 0 0.45rem;
  border-radius: 999px;
  background: var(--kv-brown);
  color: var(--kv-gold-light);
  font-size: 0.72rem;
  font-weight: 800;
  display: inline-grid;
  place-items: center;
}
.muted {
  color: var(--kv-muted);
  text-align: center;
  padding: 2rem 0;
}
.empty {
  text-align: center;
  padding: 2.5rem 1rem;
  background: var(--kv-surface);
  border-radius: 20px;
  border: 1px solid rgba(197, 160, 128, 0.18);
  box-shadow: var(--kv-shadow);
}
.heart {
  font-size: 2.2rem;
  color: var(--kv-gold);
  margin-bottom: 0.35rem;
}
.empty h3 {
  margin: 0 0 0.4rem;
  font-size: 1.35rem;
}
.empty p {
  margin: 0 0 1.1rem;
  color: var(--kv-muted);
  font-size: 0.88rem;
}
</style>
