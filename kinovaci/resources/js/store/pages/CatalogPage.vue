<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import ProductCard from '../components/ProductCard.vue'
import { useCatalog } from '../state/catalog'

const route = useRoute()
const router = useRouter()
const catalog = useCatalog()
const categoryId = ref((route.query.category as string) || '')
const q = ref('')

watch(
  () => route.query.category,
  (v) => {
    categoryId.value = (v as string) || ''
  },
)

const categories = computed(() => catalog.state.categories)

const products = computed(() => {
  let list = catalog.byCategory(categoryId.value || null)
  const needle = q.value.trim().toLowerCase()
  if (needle) {
    list = list.filter(
      (p) =>
        p.name.toLowerCase().includes(needle) ||
        p.description.toLowerCase().includes(needle),
    )
  }
  return list
})

function selectCategory(id: string) {
  categoryId.value = id
  router.replace({
    name: 'catalog',
    query: id ? { category: id } : {},
  })
}
</script>

<template>
  <div class="page kv-container">
    <div class="kv-section-title">
      <h2>Boutique</h2>
    </div>

    <input
      v-model="q"
      class="kv-input search"
      type="search"
      placeholder="Rechercher dans la boutique…"
    />

    <div class="chips">
      <button type="button" :class="{ on: !categoryId }" @click="selectCategory('')">Tout</button>
      <button
        v-for="c in categories"
        :key="c.id"
        type="button"
        :class="{ on: categoryId === c.id }"
        @click="selectCategory(c.id)"
      >
        {{ c.name }}
      </button>
    </div>

    <div v-if="products.length" class="kv-grid-products">
      <ProductCard v-for="p in products" :key="p.id" :product="p" />
    </div>
    <p v-else class="empty">
      {{ q.trim() ? 'Aucun résultat pour cette recherche.' : 'Aucun article dans cet univers.' }}
    </p>
  </div>
</template>

<style scoped>
.page {
  padding: 1.1rem 0 2rem;
}
.search {
  margin-bottom: 0.9rem;
}
.chips {
  display: flex;
  gap: 0.5rem;
  overflow-x: auto;
  margin-bottom: 1.1rem;
  padding-bottom: 0.2rem;
  scrollbar-width: none;
}
.chips::-webkit-scrollbar {
  display: none;
}
.chips button {
  flex: 0 0 auto;
  border: 1px solid rgba(197, 160, 128, 0.35);
  background: var(--kv-cream);
  color: var(--kv-muted);
  border-radius: 999px;
  padding: 0.45rem 0.9rem;
  font-size: 0.75rem;
  font-weight: 700;
  cursor: pointer;
}
.chips button.on {
  background: linear-gradient(135deg, #3e2723, #251614);
  color: var(--kv-gold-light);
  border-color: transparent;
}
.empty {
  text-align: center;
  color: var(--kv-muted);
  padding: 2rem 0;
}
</style>
