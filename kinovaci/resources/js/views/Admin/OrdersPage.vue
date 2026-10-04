<script setup lang="ts">
import { onMounted, ref } from 'vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { api } from '@/api/client'
import ListPager from '@/components/admin/ListPager.vue'
import ActionButton from '@/components/admin/ActionButton.vue'
import StatusBadge from '@/components/admin/StatusBadge.vue'
import TableState from '@/components/admin/TableState.vue'
import FormField from '@/components/admin/FormField.vue'
import AdminIcon from '@/components/admin/AdminIcon.vue'

const loading = ref(true)
const error = ref('')
const orders = ref<any[]>([])
const selected = ref<any | null>(null)
const tracking = ref('')
const carrier = ref('')

const page = ref(1)
const lastPage = ref(1)
const total = ref(0)

async function load(p = page.value) {
  loading.value = true
  error.value = ''
  try {
    const res = await api<any>(`/admin/orders?page=${p}&per_page=10`)
    if (!res.data?.length && p > 1) return await load(p - 1)
    orders.value = res.data || []
    page.value = res.current_page || 1
    lastPage.value = res.last_page || 1
    total.value = res.total || 0
  } catch (e: any) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

async function open(order: any) {
  error.value = ''
  try {
    const res = await api<{ data: any }>(`/admin/orders/${order.id}`)
    selected.value = res.data
    tracking.value = res.data.tracking_number || ''
    carrier.value = res.data.carrier || ''
  } catch (e: any) {
    error.value = e.message
  }
}

async function updateStatus(status: string) {
  if (!selected.value) return
  error.value = ''
  try {
    const res = await api<{ data: any }>(`/admin/orders/${selected.value.id}`, {
      method: 'PUT',
      json: {
        status,
        tracking_number: tracking.value || selected.value.tracking_number || null,
        carrier: carrier.value || selected.value.carrier || null,
      },
    })
    selected.value = res.data
    tracking.value = res.data.tracking_number || ''
    carrier.value = res.data.carrier || ''
    await load()
  } catch (e: any) {
    error.value = e.message
    // Remet le sélecteur sur le statut réellement enregistré.
    const current = selected.value
    selected.value = null
    await open(current)
    error.value = e.message
  }
}

async function updatePayment(paymentStatus: 'paid' | 'unpaid') {
  if (!selected.value) return
  error.value = ''
  try {
    const res = await api<{ data: any }>(`/admin/orders/${selected.value.id}`, {
      method: 'PUT',
      json: { payment_status: paymentStatus },
    })
    selected.value = res.data
    await load()
  } catch (e: any) {
    error.value = e.message
  }
}

async function saveTracking() {
  if (!selected.value) return
  await updateStatus(selected.value.status)
}

const statusLabels: Record<string, string> = {
  pending: 'En attente',
  processing: 'Confirmée',
  shipped: 'Expédiée',
  delivered: 'Livrée',
  cancelled: 'Annulée',
}

const statusTones: Record<string, 'warning' | 'info' | 'purple' | 'success' | 'error'> = {
  pending: 'warning',
  processing: 'info',
  shipped: 'purple',
  delivered: 'success',
  cancelled: 'error',
}

const formatDate = (iso: string) =>
  new Intl.DateTimeFormat('fr-FR', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' }).format(new Date(iso))

const money = (v: number) =>
  new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'XOF', maximumFractionDigits: 0 }).format(Number(v) || 0)

onMounted(() => load())
</script>

<template>
  <AdminLayout>
    <div class="space-y-6">
      <div>
        <h1 class="text-2xl font-semibold text-gray-800 dark:text-white">Commandes</h1>
        <p class="text-sm text-gray-500 mt-1">Suivi et statut des ventes</p>
      </div>

      <div v-if="error" class="rounded-lg border border-error-200 bg-error-50 px-4 py-3 text-error-700">{{ error }}</div>

      <div class="grid grid-cols-1 gap-6 xl:grid-cols-3">
        <div class="admin-card self-start xl:col-span-2">
          <div class="admin-card-header">
            <h2 class="font-semibold text-gray-800 dark:text-white">Toutes les commandes</h2>
          </div>
          <TableState :loading="loading" :empty="!orders.length" empty-text="Aucune commande pour le moment">
            <div class="overflow-x-auto">
              <table class="admin-table min-w-[680px]">
                <thead>
                  <tr>
                    <th>Commande</th>
                    <th>Client</th>
                    <th>Statut</th>
                    <th class="text-right">Total</th>
                    <th class="text-right">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  <tr
                    v-for="o in orders"
                    :key="o.id"
                    class="cursor-pointer"
                    :class="{ 'is-selected': selected?.id === o.id }"
                    @click="open(o)"
                  >
                    <td>
                      <p class="font-medium text-gray-800 dark:text-white">{{ o.reference }}</p>
                      <p class="text-xs text-gray-500">{{ formatDate(o.created_at) }}</p>
                    </td>
                    <td>
                      <p class="text-gray-800 dark:text-white">{{ o.customer_name }}</p>
                      <p class="text-xs text-gray-500">{{ o.customer_phone }}</p>
                    </td>
                    <td>
                      <div class="flex flex-wrap gap-1">
                        <StatusBadge :label="statusLabels[o.status] || o.status" :tone="statusTones[o.status] || 'gray'" />
                        <StatusBadge v-if="o.payment_status === 'paid'" label="Payée" tone="success" :dot="false" />
                      </div>
                    </td>
                    <td class="whitespace-nowrap text-right font-semibold text-gray-800 dark:text-white">{{ money(o.total) }}</td>
                    <td>
                      <div class="flex justify-end">
                        <ActionButton icon="eye" label="Voir le détail" variant="brand" @click.stop="open(o)" />
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </TableState>
          <ListPager :page="page" :last-page="lastPage" :total="total" @change="load" />
        </div>

        <div class="admin-card self-start">
          <div class="admin-card-header">
            <div class="min-w-0">
              <h2 class="font-semibold text-gray-800 dark:text-white">{{ selected ? selected.reference : 'Détail de la commande' }}</h2>
              <p v-if="selected" class="text-xs text-gray-500">{{ formatDate(selected.created_at) }}</p>
            </div>
            <StatusBadge v-if="selected" :label="statusLabels[selected.status] ?? selected.status" :tone="statusTones[selected.status] ?? 'info'" />
          </div>
          <div v-if="!selected" class="px-5 py-14 text-center text-sm text-gray-500">Cliquez sur une commande pour l’afficher ici.</div>
          <div v-else class="divide-y divide-gray-100 text-sm dark:divide-gray-800">
            <section class="space-y-2 p-5">
              <p class="admin-section-title">Client</p>
              <p class="font-medium text-gray-800 dark:text-white">{{ selected.customer_name }}</p>
              <p class="flex items-center gap-2 text-gray-600 dark:text-gray-300">
                {{ selected.customer_phone }}
                <a :href="`tel:${selected.customer_phone}`" class="inline-flex items-center gap-1 rounded-full bg-brand-50 px-2.5 py-0.5 text-xs font-medium text-brand-600 dark:bg-white/10 dark:text-brand-300">
                  <AdminIcon name="phone" :size="12" /> Appeler
                </a>
              </p>
              <p class="text-gray-600 dark:text-gray-300">
                <span class="font-medium text-gray-800 dark:text-white">{{ selected.is_delivery === false ? 'Retrait en boutique' : 'Livraison' }}</span>
                <template v-if="selected.address || selected.city"> — {{ [selected.address, selected.city].filter(Boolean).join(', ') }}</template>
              </p>
              <p v-if="selected.delivery_details" class="rounded-lg bg-gray-50 p-2.5 dark:bg-white/5">
                <span class="block text-xs text-gray-500">Précisions du client</span>
                {{ selected.delivery_details }}
              </p>
              <a v-if="selected.maps_url" :href="selected.maps_url" target="_blank" rel="noopener" class="inline-block text-brand-500 hover:underline dark:text-brand-300">
                📍 Voir la position GPS du client
              </a>
            </section>

            <section class="space-y-2 p-5">
              <p class="admin-section-title">Articles</p>
              <ul class="space-y-2">
                <li v-for="item in selected.items" :key="item.id" class="flex justify-between gap-3">
                  <div class="min-w-0">
                    <p class="text-gray-800 dark:text-white">{{ item.product_name }} <span class="text-gray-500">× {{ item.quantity }}</span></p>
                    <p v-if="item.selected_size || item.selected_color" class="text-xs text-gray-500">
                      {{ [item.selected_size && `Taille ${item.selected_size}`, item.selected_color].filter(Boolean).join(' · ') }}
                    </p>
                  </div>
                  <span class="shrink-0 text-gray-700 dark:text-gray-300">{{ money(item.line_total) }}</span>
                </li>
              </ul>
              <div class="flex items-baseline justify-between border-t border-dashed border-gray-200 pt-2 dark:border-gray-700">
                <span class="font-semibold text-gray-800 dark:text-white">Total</span>
                <span class="text-right">
                  <span class="text-base font-semibold text-gray-800 dark:text-white">{{ money(selected.total) }}</span>
                  <span v-if="selected.is_delivery !== false && Number(selected.shipping) === 0" class="block text-xs text-gray-500">livraison réglée au livreur</span>
                </span>
              </div>
            </section>

            <section class="space-y-3 p-5">
              <div class="flex items-center justify-between">
                <p class="admin-section-title">Paiement à la livraison</p>
                <StatusBadge :label="selected.payment_status === 'paid' ? 'Payé' : 'Non payé'" :tone="selected.payment_status === 'paid' ? 'success' : 'warning'" />
              </div>
              <div class="flex flex-wrap gap-2">
                <button
                  v-if="selected.payment_status !== 'paid' && selected.status !== 'cancelled'"
                  type="button"
                  class="admin-btn-primary"
                  @click="updatePayment('paid')"
                >
                  <AdminIcon name="check" :size="16" /> Marquer payé
                </button>
                <button v-else-if="selected.payment_status === 'paid'" type="button" class="admin-btn-secondary" @click="updatePayment('unpaid')">
                  Annuler le paiement
                </button>
                <a v-if="selected.invoice_url" :href="selected.invoice_url" target="_blank" rel="noopener" class="admin-btn-secondary">
                  <AdminIcon name="file" :size="16" />
                  {{ selected.invoice_status === 'confirmed' ? 'Facture payée' : 'Facture provisoire' }}
                </a>
              </div>
            </section>

            <section class="space-y-4 p-5">
              <FormField label="Statut de la commande" for="o-status" hint="Le client reçoit une notification à chaque changement. « Livrée » marque aussi la commande payée.">
                <select
                  id="o-status"
                  class="admin-input"
                  :value="selected.status"
                  @change="updateStatus(($event.target as HTMLSelectElement).value)"
                >
                  <option value="pending">En attente</option>
                  <option value="processing">Confirmée / en préparation</option>
                  <option value="shipped">Expédiée</option>
                  <option value="delivered">Livrée (marque payée)</option>
                  <option value="cancelled">Annulée</option>
                </select>
              </FormField>
            </section>

            <section class="space-y-4 p-5">
              <p class="admin-section-title">Suivi de livraison (facultatif)</p>
              <FormField label="Numéro de suivi" for="o-tracking" hint="Visible par le client dans le suivi de sa commande.">
                <input id="o-tracking" v-model="tracking" maxlength="120" class="admin-input" placeholder="Ex. KIN-TRACK-0042" />
              </FormField>
              <FormField label="Livreur / transporteur" for="o-carrier">
                <input id="o-carrier" v-model="carrier" maxlength="80" class="admin-input" placeholder="Ex. KINOVA Express, Yango…" />
              </FormField>
              <button type="button" class="admin-btn-secondary w-full justify-center" @click="saveTracking">Enregistrer le suivi</button>
            </section>
          </div>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>
