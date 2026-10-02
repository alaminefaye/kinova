<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { api } from '../api/client'
import KinovaLoader from '../components/KinovaLoader.vue'
import OrderCard from '../components/OrderCard.vue'
import CancelOrderModal from '../components/CancelOrderModal.vue'
import type { OrderSummary } from '../lib/types'

type Filter = 'all' | 'ongoing' | 'delivered' | 'cancelled'

const filters: { key: Filter; label: string; match: (o: OrderSummary) => boolean }[] = [
  { key: 'all', label: 'Toutes', match: () => true },
  {
    key: 'ongoing',
    label: 'En cours',
    match: (o) => ['pending', 'processing', 'shipped'].includes(o.status),
  },
  { key: 'delivered', label: 'Livrées', match: (o) => o.status === 'delivered' },
  { key: 'cancelled', label: 'Annulées', match: (o) => o.status === 'cancelled' },
]

const router = useRouter()
const orders = ref<OrderSummary[]>([])
const loading = ref(false)
const filter = ref<Filter>('all')
const cancelling = ref<OrderSummary | null>(null)
const toast = ref('')

const current = computed(() => filters.find((f) => f.key === filter.value)!)
const visible = computed(() => orders.value.filter(current.value.match))

async function load() {
  loading.value = true
  try {
    const res = await api<any>('/customer/orders')
    orders.value = Array.isArray(res.data) ? res.data : []
  } catch {
    /* garde la liste déjà chargée */
  } finally {
    loading.value = false
  }
}

function onCancelled(order: OrderSummary) {
  cancelling.value = null
  orders.value = orders.value.map((o) => (o.reference === order.reference ? order : o))
  toast.value = `Commande ${order.reference} annulée.`
  setTimeout(() => (toast.value = ''), 3500)
}

onMounted(load)
</script>

<template>
  <div class="page kv-container">
    <header class="head">
      <button type="button" class="back" aria-label="Retour" @click="router.back()">←</button>
      <h2>Mes commandes</h2>
      <button type="button" class="refresh" :disabled="loading" @click="load">↻</button>
    </header>

    <div class="filters">
      <button
        v-for="f in filters"
        :key="f.key"
        type="button"
        :class="{ active: filter === f.key }"
        @click="filter = f.key"
      >
        {{ f.label }} ({{ orders.filter(f.match).length }})
      </button>
    </div>

    <KinovaLoader v-if="loading && !orders.length" compact message="Chargement des commandes" :size="58" />

    <div v-else-if="!visible.length" class="empty">
      <div class="icon">🛍️</div>
      <p>
        {{ orders.length ? `Aucune commande dans « ${current.label} ».` : 'Aucune commande pour le moment.' }}
      </p>
      <button v-if="!orders.length" type="button" class="kv-btn kv-btn-dark" @click="router.push({ name: 'catalog' })">
        DÉCOUVRIR LA BOUTIQUE
      </button>
    </div>

    <OrderCard v-for="o in visible" v-else :key="o.reference" :order="o" show-cancel @cancel="cancelling = $event" />

    <CancelOrderModal
      v-if="cancelling"
      :order="cancelling"
      @close="cancelling = null"
      @cancelled="onCancelled"
    />

    <div v-if="toast" class="toast">{{ toast }}</div>
  </div>
</template>

<style scoped>
.page {
  padding: 1rem 0 2rem;
}
.head {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-bottom: 1rem;
}
.head h2 {
  flex: 1;
  margin: 0;
  font-family: var(--kv-font-display);
  color: var(--kv-brown);
}
.back,
.refresh {
  width: 40px;
  height: 40px;
  border-radius: 999px;
  border: 1px solid rgba(197, 160, 128, 0.35);
  background: var(--kv-surface);
  color: var(--kv-brown);
  font-size: 1.1rem;
  cursor: pointer;
}
.filters {
  display: flex;
  gap: 0.5rem;
  overflow-x: auto;
  padding-bottom: 0.25rem;
  margin-bottom: 1rem;
}
.filters button {
  flex-shrink: 0;
  border: 1px solid rgba(62, 39, 35, 0.2);
  background: var(--kv-surface);
  color: var(--kv-brown);
  border-radius: 999px;
  padding: 0.45rem 0.9rem;
  font-weight: 700;
  font-size: 0.78rem;
  cursor: pointer;
}
.filters button.active {
  background: var(--kv-brown);
  color: var(--kv-cream);
  border-color: var(--kv-brown);
}
.empty {
  text-align: center;
  padding: 3rem 1rem;
  color: var(--kv-muted);
}
.empty .icon {
  font-size: 2.4rem;
}
.empty .kv-btn {
  margin-top: 1rem;
}
.toast {
  position: fixed;
  left: 50%;
  bottom: 1.5rem;
  transform: translateX(-50%);
  background: var(--kv-brown);
  color: var(--kv-cream);
  padding: 0.75rem 1.1rem;
  border-radius: 14px;
  font-size: 0.85rem;
  z-index: 95;
  box-shadow: var(--kv-shadow);
}
</style>
