<script setup lang="ts">
import { onMounted, ref } from 'vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { api } from '@/api/client'
import ListPager from '@/components/admin/ListPager.vue'
import ActionButton from '@/components/admin/ActionButton.vue'
import StatusBadge from '@/components/admin/StatusBadge.vue'
import TableState from '@/components/admin/TableState.vue'

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

        <div class="self-start rounded-2xl border border-gray-200 bg-white p-5 shadow-theme-xs dark:border-gray-800 dark:bg-white/[0.03]">
          <h2 class="font-semibold text-gray-800 dark:text-white mb-4">Détail</h2>
          <div v-if="!selected" class="text-sm text-gray-500">Sélectionnez une commande</div>
          <div v-else class="space-y-3 text-sm">
            <p><span class="text-gray-500">Réf.</span> {{ selected.reference }}</p>
            <p><span class="text-gray-500">Client</span> {{ selected.customer_name }}</p>
            <p>
              <span class="text-gray-500">Tél.</span> {{ selected.customer_phone }}
              <a :href="`tel:${selected.customer_phone}`" class="ml-2 text-brand-500">Appeler</a>
            </p>
            <p>
              <span class="text-gray-500">{{ selected.is_delivery === false ? 'Retrait' : 'Livraison' }}</span>
              {{ selected.address }}, {{ selected.city }}
            </p>
            <p v-if="selected.delivery_details" class="rounded-lg bg-gray-50 p-2 dark:bg-white/5">
              <span class="text-gray-500 block text-xs">Précisions du client</span>
              {{ selected.delivery_details }}
            </p>
            <p v-if="selected.maps_url">
              <a :href="selected.maps_url" target="_blank" rel="noopener" class="text-brand-500">📍 Voir la position GPS du client</a>
            </p>
            <p>
              <span class="text-gray-500">Paiement</span> à la livraison —
              <span :class="selected.payment_status === 'paid' ? 'text-success-600 font-medium' : 'text-warning-600'">
                {{ selected.payment_status === 'paid' ? 'payé' : 'non payé' }}
              </span>
            </p>
            <p class="font-semibold">
              Total {{ money(selected.total) }}
              <span v-if="selected.is_delivery !== false && Number(selected.shipping) === 0" class="text-xs font-normal text-gray-500">(livraison réglée au livreur)</span>
            </p>
            <div class="flex flex-wrap gap-2">
              <a
                v-if="selected.invoice_url"
                :href="selected.invoice_url"
                target="_blank"
                rel="noopener"
                class="rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-gray-700"
              >
                {{ selected.invoice_status === 'confirmed' ? 'Facture payée' : 'Facture provisoire' }}
              </a>
              <button
                v-if="selected.payment_status !== 'paid' && selected.status !== 'cancelled'"
                class="rounded-lg border border-success-300 px-3 py-2 text-sm text-success-700"
                @click="updatePayment('paid')"
              >
                Marquer payé
              </button>
              <button
                v-else-if="selected.payment_status === 'paid'"
                class="rounded-lg border border-gray-200 px-3 py-2 text-sm text-gray-500 dark:border-gray-700"
                @click="updatePayment('unpaid')"
              >
                Annuler le paiement
              </button>
            </div>

            <label class="block text-gray-500 mt-2">N° suivi</label>
            <input v-model="tracking" class="w-full rounded-lg border border-gray-200 px-3 py-2.5 dark:border-gray-700 dark:bg-gray-900" placeholder="KIN-TRACK-…" />
            <label class="block text-gray-500 mt-2">Transporteur</label>
            <input v-model="carrier" class="w-full rounded-lg border border-gray-200 px-3 py-2.5 dark:border-gray-700 dark:bg-gray-900" placeholder="KINOVA Express" />
            <button class="rounded-lg border border-gray-200 px-3 py-2 text-sm" @click="saveTracking">Enregistrer suivi</button>

            <ul class="divide-y divide-gray-100 dark:divide-gray-800">
              <li v-for="item in selected.items" :key="item.id" class="py-2 flex justify-between">
                <span>{{ item.product_name }} × {{ item.quantity }}</span>
                <span>{{ money(item.line_total) }}</span>
              </li>
            </ul>

            <label class="block text-gray-500 mt-2">Changer statut</label>
            <select
              class="w-full rounded-lg border border-gray-200 px-3 py-2.5 dark:border-gray-700 dark:bg-gray-900"
              :value="selected.status"
              @change="updateStatus(($event.target as HTMLSelectElement).value)"
            >
              <option value="pending">En attente</option>
              <option value="processing">Confirmée / en préparation</option>
              <option value="shipped">Expédiée</option>
              <option value="delivered">Livrée (marque payée)</option>
              <option value="cancelled">Annulée</option>
            </select>
          </div>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>
