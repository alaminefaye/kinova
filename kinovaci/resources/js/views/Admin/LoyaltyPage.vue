<script setup lang="ts">
import { onMounted, ref } from 'vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { api } from '@/api/client'

const loading = ref(true)
const error = ref('')
const customers = ref<any[]>([])
const points = ref(100)
const note = ref('Bonus admin')

async function load() {
  loading.value = true
  error.value = ''
  try {
    const res = await api<any>('/admin/loyalty/customers')
    customers.value = res.data || []
  } catch (e: any) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

async function adjust(userId: number, delta: number) {
  error.value = ''
  try {
    await api(`/admin/loyalty/customers/${userId}/adjust`, {
      method: 'POST',
      json: { points: delta, description: note.value || 'Ajustement admin' },
    })
    await load()
  } catch (e: any) {
    error.value = e.message
  }
}

onMounted(load)
</script>

<template>
  <AdminLayout>
    <div class="space-y-6">
      <div>
        <h1 class="text-2xl font-semibold text-gray-800 dark:text-white">Fidélité VIP</h1>
        <p class="text-sm text-gray-500 mt-1">Points et paliers clients</p>
      </div>

      <div v-if="error" class="rounded-lg border border-error-200 bg-error-50 px-4 py-3 text-error-700">{{ error }}</div>

      <div class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03] flex flex-wrap gap-3 items-end">
        <label class="text-sm">
          <span class="text-gray-500 block mb-1">Points (±)</span>
          <input v-model.number="points" type="number" class="rounded-lg border border-gray-200 px-3 py-2.5 dark:border-gray-700 dark:bg-gray-900 w-32" />
        </label>
        <label class="text-sm flex-1 min-w-[200px]">
          <span class="text-gray-500 block mb-1">Motif</span>
          <input v-model="note" class="w-full rounded-lg border border-gray-200 px-3 py-2.5 dark:border-gray-700 dark:bg-gray-900" />
        </label>
      </div>

      <div class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03] overflow-x-auto">
        <div v-if="loading" class="text-gray-500">Chargement…</div>
        <table v-else class="w-full text-sm min-w-[700px]">
          <thead>
            <tr class="border-b border-gray-100 text-left text-gray-500 dark:border-gray-800">
              <th class="py-2">Client</th>
              <th>Tier</th>
              <th>Points</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="c in customers" :key="c.id" class="border-b border-gray-50 dark:border-gray-800">
              <td class="py-3">
                <div class="font-medium text-gray-800 dark:text-white">{{ c.name }}</div>
                <div class="text-xs text-gray-500">{{ c.email }}</div>
              </td>
              <td class="uppercase">{{ c.vip_tier }}</td>
              <td>{{ c.loyalty_points }}</td>
              <td class="text-right space-x-2">
                <button class="text-brand-500" @click="adjust(c.id, Math.abs(points || 0))">+ points</button>
                <button class="text-error-500" @click="adjust(c.id, -Math.abs(points || 0))">− points</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </AdminLayout>
</template>
