<script setup lang="ts">
import { computed } from 'vue'
import { formatMoney, statusLabel } from '../lib/format'
import type { OrderSummary } from '../lib/types'

const props = defineProps<{ order: OrderSummary; showCancel?: boolean }>()
const emit = defineEmits<{ cancel: [order: OrderSummary] }>()

const itemsCount = computed(() => props.order.items?.length ?? 0)
const invoiceLabel = computed(() => {
  if (props.order.invoice_status === 'confirmed') return 'Facture payée'
  if (props.order.invoice_status === 'cancelled') return 'Facture annulée'
  return 'Facture provisoire'
})

function formatDate(iso?: string) {
  if (!iso) return ''
  try {
    return new Intl.DateTimeFormat('fr-FR').format(new Date(iso))
  } catch {
    return ''
  }
}

function openInvoice() {
  if (props.order.invoice_url) window.open(props.order.invoice_url, '_blank', 'noopener')
}
</script>

<template>
  <article class="order-card" :class="{ clickable: !!order.invoice_url }" @click="openInvoice">
    <div class="row">
      <div class="bag">🧾</div>
      <div class="body">
        <div class="line">
          <strong>{{ order.reference }}</strong>
          <span class="badge" :class="`s-${order.status}`">{{ statusLabel(order.status) }}</span>
        </div>
        <div class="line">
          <p>
            {{ formatDate(order.created_at) }}
            <template v-if="itemsCount"> · {{ itemsCount }} article{{ itemsCount > 1 ? 's' : '' }}</template>
            <template v-if="order.tracking_number"> · {{ order.tracking_number }}</template>
          </p>
          <span class="total">{{ formatMoney(Number(order.total)) }}</span>
        </div>
        <p v-if="order.invoice_url" class="invoice">📄 {{ invoiceLabel }} ›</p>
      </div>
    </div>
    <button
      v-if="showCancel && order.can_cancel"
      type="button"
      class="cancel"
      @click.stop="emit('cancel', order)"
    >
      ✕ ANNULER LA COMMANDE
    </button>
  </article>
</template>

<style scoped>
.order-card {
  background: var(--kv-surface);
  border-radius: 18px;
  padding: 1rem 1.1rem;
  border: 1px solid rgba(197, 160, 128, 0.16);
  box-shadow: var(--kv-shadow);
  margin-bottom: 0.75rem;
}
.order-card.clickable {
  cursor: pointer;
}
.row {
  display: flex;
  gap: 0.85rem;
  align-items: center;
}
.bag {
  width: 44px;
  height: 44px;
  border-radius: 14px;
  display: grid;
  place-items: center;
  background: var(--kv-surface-muted);
  flex-shrink: 0;
}
.body {
  flex: 1;
  min-width: 0;
}
.line {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.5rem;
}
strong {
  font-size: 0.95rem;
  color: var(--kv-brown);
}
p {
  margin: 0.2rem 0 0;
  color: var(--kv-muted);
  font-size: 0.8rem;
}
.total {
  font-weight: 800;
  font-size: 0.9rem;
  color: var(--kv-brown);
  white-space: nowrap;
}
.invoice {
  color: #b8860b;
  font-weight: 700;
  font-size: 0.75rem;
}
.badge {
  padding: 3px 8px;
  border-radius: 8px;
  font-size: 0.65rem;
  font-weight: 700;
  white-space: nowrap;
  background: var(--kv-surface-muted);
  color: var(--kv-brown);
}
.s-pending { background: #fff4d6; color: #8a6200; }
.s-processing { background: #e3f2fd; color: #1565c0; }
.s-shipped { background: #ede7f6; color: #5e35b1; }
.s-delivered { background: #e8f5e9; color: #2e7d32; }
.s-cancelled { background: #fdecea; color: #c62828; }
.cancel {
  margin-top: 0.8rem;
  width: 100%;
  padding: 0.65rem;
  border-radius: 12px;
  border: 1px solid #e57373;
  background: transparent;
  color: #c62828;
  font-weight: 800;
  font-size: 0.75rem;
  letter-spacing: 0.06em;
  cursor: pointer;
}
.cancel:hover {
  background: #fdecea;
}
</style>
