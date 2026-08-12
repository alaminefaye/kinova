<script setup lang="ts">
import { computed } from 'vue'
import ProductCard from '../components/ProductCard.vue'
import { useCatalog } from '../state/catalog'
import { useFavorites } from '../state/favorites'

const catalog = useCatalog()
const favorites = useFavorites()

const products = computed(() =>
  catalog.state.products.filter((p) => favorites.isFavorite(p.id)),
)
</script>

<template>
  <div class="page kv-container">
    <div class="kv-section-title">
      <h2>Favoris</h2>
    </div>
    <div v-if="products.length" class="kv-grid-products">
      <ProductCard v-for="p in products" :key="p.id" :product="p" />
    </div>
    <p v-else class="empty">Aucun favori pour l’instant.</p>
  </div>
</template>

<style scoped>
.page {
  padding: 1.1rem 0 2rem;
}
.empty {
  text-align: center;
  color: var(--kv-muted);
  padding: 2rem 0;
}
</style>
