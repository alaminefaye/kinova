<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import ProductCard from '../components/ProductCard.vue'
import { useCatalog } from '../state/catalog'

const router = useRouter()
const catalog = useCatalog()
const q = ref('')
const inputEl = ref<HTMLInputElement | null>(null)

const suggestions = [
  'Sac',
  'Montre',
  'Parfum',
  'Rouge',
  'Soin',
  'Maison',
  'Mode',
  'Beauté',
]

const results = computed(() => {
  const needle = q.value.trim()
  if (!needle) return []
  return catalog.search(needle)
})

onMounted(() => {
  inputEl.value?.focus()
})

function pick(term: string) {
  q.value = term
  inputEl.value?.focus()
}

function clear() {
  q.value = ''
  inputEl.value?.focus()
}
</script>

<template>
  <div class="search-page">
    <header class="head">
      <div class="kv-container row">
        <button class="round" type="button" @click="router.back()" aria-label="Retour">←</button>
        <div class="field">
          <span class="ico">⌕</span>
          <input
            ref="inputEl"
            v-model="q"
            type="search"
            placeholder="Rechercher une pièce…"
            autocomplete="off"
          />
          <button v-if="q" class="clear" type="button" @click="clear" aria-label="Effacer">×</button>
        </div>
      </div>
    </header>

    <div class="body kv-container">
      <template v-if="!q.trim()">
        <p class="label">Suggestions</p>
        <div class="chips">
          <button v-for="s in suggestions" :key="s" type="button" @click="pick(s)">{{ s }}</button>
        </div>
        <p class="hint">Tapez un mot pour trouver un article KINOVA.</p>
      </template>

      <template v-else-if="!results.length">
        <div class="empty">
          <strong>Aucun résultat</strong>
          <p>Essayez un autre mot-clé ou univers.</p>
        </div>
      </template>

      <template v-else>
        <p class="count">{{ results.length }} résultat{{ results.length > 1 ? 's' : '' }}</p>
        <div class="kv-grid-products">
          <ProductCard v-for="p in results" :key="p.id" :product="p" />
        </div>
      </template>
    </div>
  </div>
</template>

<style scoped>
.search-page {
  min-height: 100vh;
  background: var(--kv-bg);
}
.head {
  background: linear-gradient(135deg, #3e2723, #251614);
  border-radius: 0 0 30px 30px;
  padding: 1rem 0 1.35rem;
}
.row {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}
.round {
  width: 44px;
  height: 44px;
  border-radius: 999px;
  border: 1px solid rgba(197, 160, 128, 0.35);
  background: rgba(255, 255, 255, 0.1);
  color: var(--kv-cream);
  cursor: pointer;
  font-size: 1.1rem;
  flex-shrink: 0;
}
.field {
  flex: 1;
  height: 48px;
  display: flex;
  align-items: center;
  gap: 0.55rem;
  padding: 0 0.9rem;
  border-radius: 26px;
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(197, 160, 128, 0.4);
}
.ico {
  color: var(--kv-gold);
}
.field input {
  flex: 1;
  border: none;
  background: transparent;
  color: var(--kv-cream);
  outline: none;
  font-size: 0.92rem;
  font-weight: 500;
}
.field input::placeholder {
  color: rgba(253, 251, 247, 0.45);
}
.clear {
  width: 22px;
  height: 22px;
  border-radius: 999px;
  border: none;
  background: rgba(255, 255, 255, 0.12);
  color: var(--kv-gold-light);
  cursor: pointer;
  line-height: 1;
}
.body {
  padding: 1.15rem 0 2rem;
}
.label {
  margin: 0 0 0.65rem;
  font-size: 0.7rem;
  font-weight: 800;
  letter-spacing: 0.12em;
  color: var(--kv-muted);
  text-transform: uppercase;
}
.chips {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  margin-bottom: 1.25rem;
}
.chips button {
  border: 1px solid rgba(197, 160, 128, 0.35);
  background: var(--kv-surface);
  color: var(--kv-brown);
  border-radius: 999px;
  padding: 0.5rem 0.9rem;
  font-size: 0.8rem;
  font-weight: 700;
  cursor: pointer;
}
.hint {
  color: var(--kv-muted);
  font-size: 0.85rem;
}
.count {
  margin: 0 0 0.75rem;
  font-size: 0.7rem;
  font-weight: 800;
  letter-spacing: 0.1em;
  color: var(--kv-muted);
  text-transform: uppercase;
}
.empty {
  text-align: center;
  padding: 2.5rem 1rem;
  background: var(--kv-surface);
  border-radius: 18px;
  border: 1px solid rgba(197, 160, 128, 0.16);
}
.empty strong {
  display: block;
  margin-bottom: 0.35rem;
}
.empty p {
  margin: 0;
  color: var(--kv-muted);
  font-size: 0.85rem;
}
</style>
