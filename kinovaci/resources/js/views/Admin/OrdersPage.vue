<script setup lang="ts">
import { onMounted, ref } from 'vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { api } from '@/api/client'

const loading = ref(true)
const error = ref('')
const orders = ref<any[]>([])
const selected = ref<any | null>(null)
const tracking = ref('')
const carrier = ref('')

async function load() {
  loading.value = true
  error.value = ''
  try {
    const res = await api<any>('/admin/orders')
    orders.value = res.data || []
  } catch (e: any) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

async function open(order: any) {
  const res = await api<{ data: any }>(`/admin/orders/${order.id}`)
  selected.value = res.data
  tracking.value = res.data.tracking_number || ''
  carrier.value = res.data.carrier || ''
}

async function updateStatus(status: string) {
  if (!selected.value) return
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
}

async function saveTracking() {
  if (!selected.value) return
  await updateStatus(selected.value.status)
}

const money = (v: number) =>
  new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'EUR' }).format(Number(v) || 0)

onMounted(load)
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
        <div class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03] xl:col-span-2 overflow-x-auto">
          <div v-if="loading" class="text-gray-500">Chargement…</div>
          <table v-else class="w-full text-sm min-w-[640px]">
            <thead>
              <tr class="border-b border-gray-100 text-left text-gray-500 dark:border-gray-800">
                <th class="py-2">Réf.</th>
                <th>Client</th>
                <th>Statut</th>
                <th>Total</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="o in orders" :key="o.id" class="border-b border-gray-50 dark:border-gray-800">
                <td class="py-3 font-medium text-gray-800 dark:text-white">{{ o.reference }}</td>
                <td>{{ o.customer_name }}</td>
                <td>
                  <span class="rounded-full bg-brand-50 px-2 py-1 text-xs text-brand-600">{{ o.status }}</span>
                </td>
                <td>{{ money(o.total) }}</td>
                <td class="text-right">
                  <button class="text-brand-500" @click="open(o)">Détail</button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03]">
          <h2 class="font-semibold text-gray-800 dark:text-white mb-4">Détail</h2>
          <div v-if="!selected" class="text-sm text-gray-500">Sélectionnez une commande</div>
          <div v-else class="space-y-3 text-sm">
            <p><span class="text-gray-500">Réf.</span> {{ selected.reference }}</p>
            <p><span class="text-gray-500">Client</span> {{ selected.customer_name }}</p>
            <p><span class="text-gray-500">Tél.</span> {{ selected.customer_phone }}</p>
            <p><span class="text-gray-500">Adresse</span> {{ selected.address }}, {{ selected.city }}</p>
            <p><span class="text-gray-500">Paiement</span> {{ selected.payment_method }}</p>
            <p class="font-semibold">Total {{ money(selected.total) }}</p>

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
              <option value="pending">pending</option>
              <option value="processing">processing</option>
              <option value="shipped">shipped</option>
              <option value="delivered">delivered</option>
              <option value="cancelled">cancelled</option>
            </select>
          </div>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>
