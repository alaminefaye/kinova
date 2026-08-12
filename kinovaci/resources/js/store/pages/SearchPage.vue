<script setup lang="ts">
import { computed, ref } from 'vue'
import ProductCard from '../components/ProductCard.vue'
import { useCatalog } from '../state/catalog'

const catalog = useCatalog()
const q = ref('')
const results = computed(() => catalog.search(q.value))
</script>

<template>
  <div class="page kv-container">
    <div class="kv-section-title">
      <h2>Recherche</h2>
    </div>
    <input v-model="q" class="kv-input" placeholder="Un soin, un sac, une senteur…" autofocus />
    <div v-if="results.length" class="kv-grid-products list">
      <ProductCard v-for="p in results" :key="p.id" :product="p" />
    </div>
    <p v-else class="empty">{{ q.trim() ? 'Aucun résultat' : 'Tapez pour chercher' }}</p>
  </div>
</template>

<style scoped>
.page {
  padding: 1.1rem 0 2rem;
}
.list {
  margin-top: 1rem;
}
.empty {
  text-align: center;
  color: var(--kv-muted);
  padding: 2rem 0;
}
</style>
