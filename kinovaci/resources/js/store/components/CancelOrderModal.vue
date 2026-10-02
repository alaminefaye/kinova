<script setup lang="ts">
import { computed, ref } from 'vue'
import { api } from '../api/client'
import { formatMoney } from '../lib/format'
import type { OrderSummary } from '../lib/types'

const props = defineProps<{ order: OrderSummary }>()
const emit = defineEmits<{ close: []; cancelled: [order: OrderSummary] }>()

const reasons = [
  'J’ai changé d’avis',
  'Commande passée par erreur',
  'Je veux modifier ma commande',
  'Délai trop long',
  'Autre',
]
const summary = computed(() => {
  const n = props.order.items?.length ?? 0
  const total = formatMoney(Number(props.order.total))
  return n ? `${total} · ${n} article${n > 1 ? 's' : ''}` : total
})
const reason = ref<string | null>(null)
const details = ref('')
const loading = ref(false)
const error = ref('')

async function submit() {
  const parts = [
    reason.value && reason.value !== 'Autre' ? reason.value : '',
    details.value.trim(),
  ].filter(Boolean)
  loading.value = true
  error.value = ''
  try {
    const res = await api<{ data: OrderSummary }>(
      `/customer/orders/${encodeURIComponent(props.order.reference)}/cancel`,
      { method: 'POST', json: parts.length ? { reason: parts.join(' — ') } : {} },
    )
    emit('cancelled', res.data)
  } catch (e: any) {
    error.value = e?.message || 'Annulation impossible. Réessayez.'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="modal" @click.self="emit('close')">
    <div class="modal-card">
      <h4>Annuler la commande {{ order.reference }} ?</h4>
      <p class="muted">{{ summary }}. Cette action est définitive.</p>

      <p class="label">Pourquoi annulez-vous ? (facultatif)</p>
      <div class="chips">
        <button
          v-for="r in reasons"
          :key="r"
          type="button"
          :class="{ active: reason === r }"
          @click="reason = reason === r ? null : r"
        >
          {{ r }}
        </button>
      </div>
      <textarea
        v-model="details"
        class="kv-input"
        rows="2"
        maxlength="300"
        placeholder="Précisez si vous le souhaitez…"
      />
      <p v-if="error" class="error">{{ error }}</p>

      <div class="actions">
        <button type="button" class="keep" :disabled="loading" @click="emit('close')">GARDER</button>
        <button type="button" class="confirm" :disabled="loading" @click="submit">
          {{ loading ? 'Annulation…' : 'ANNULER' }}
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.modal {
  position: fixed;
  inset: 0;
  background: rgba(27, 17, 11, 0.55);
  display: grid;
  place-items: center;
  z-index: 90;
  padding: 1rem;
}
.modal-card {
  width: min(420px, 100%);
  background: var(--kv-cream);
  border-radius: 20px;
  padding: 1.25rem;
  border: 1px solid rgba(197, 160, 128, 0.3);
}
h4 {
  margin: 0 0 0.4rem;
  font-family: var(--kv-font-display);
  color: var(--kv-brown);
}
.muted {
  margin: 0 0 1rem;
  color: var(--kv-muted);
  font-size: 0.85rem;
}
.label {
  margin: 0 0 0.5rem;
  font-weight: 700;
  font-size: 0.85rem;
  color: var(--kv-brown);
}
.chips {
  display: flex;
  flex-wrap: wrap;
  gap: 0.45rem;
  margin-bottom: 0.75rem;
}
.chips button {
  border: 1px solid rgba(62, 39, 35, 0.2);
  background: var(--kv-surface);
  color: var(--kv-brown);
  border-radius: 999px;
  padding: 0.4rem 0.75rem;
  font-size: 0.78rem;
  font-weight: 600;
  cursor: pointer;
}
.chips button.active {
  background: var(--kv-brown);
  color: var(--kv-cream);
  border-color: var(--kv-brown);
}
textarea {
  width: 100%;
  resize: vertical;
}
.error {
  color: #c62828;
  font-size: 0.82rem;
  margin: 0.5rem 0 0;
}
.actions {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 0.6rem;
  margin-top: 1rem;
}
.actions button {
  height: 46px;
  border-radius: 14px;
  font-weight: 800;
  letter-spacing: 0.06em;
  font-size: 0.78rem;
  cursor: pointer;
}
.keep {
  border: 1px solid rgba(62, 39, 35, 0.25);
  background: transparent;
  color: var(--kv-brown);
}
.confirm {
  border: none;
  background: #c62828;
  color: #fff;
}
.actions button:disabled {
  opacity: 0.6;
  cursor: default;
}
</style>
