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
const customers = ref<any[]>([])
const points = ref(100)
const note = ref('Bonus admin')

const page = ref(1)
const lastPage = ref(1)
const total = ref(0)

async function load(p = page.value) {
  loading.value = true
  error.value = ''
  try {
    const res = await api<any>(`/admin/loyalty/customers?page=${p}&per_page=10`)
    if (!res.data?.length && p > 1) return await load(p - 1)
    customers.value = res.data || []
    page.value = res.current_page || 1
    lastPage.value = res.last_page || 1
    total.value = res.total || 0
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

const tierMeta: Record<string, { label: string; tone: 'gray' | 'info' | 'warning' | 'brand' }> = {
  standard: { label: 'Standard', tone: 'gray' },
  silver: { label: 'Argent', tone: 'info' },
  gold: { label: 'Or', tone: 'warning' },
  vip: { label: 'VIP', tone: 'brand' },
}

onMounted(() => load())
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

      <div class="admin-card">
        <div class="admin-card-header">
          <h2 class="font-semibold text-gray-800 dark:text-white">Clients fidèles</h2>
          <p class="text-xs text-gray-500">Les boutons + et − appliquent le nombre de points et le motif ci-dessus.</p>
        </div>
        <TableState :loading="loading" :empty="!customers.length" empty-text="Aucun client pour le moment">
          <div class="overflow-x-auto">
            <table class="admin-table min-w-[620px]">
              <thead>
                <tr>
                  <th>Client</th>
                  <th>Palier</th>
                  <th>Points</th>
                  <th class="text-right">Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="c in customers" :key="c.id">
                  <td>
                    <div class="flex items-center gap-3">
                      <span class="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-brand-50 text-sm font-semibold text-brand-600 dark:bg-white/10 dark:text-brand-300">
                        {{ (c.name || '?').charAt(0).toUpperCase() }}
                      </span>
                      <div class="min-w-0">
                        <p class="font-medium text-gray-800 dark:text-white">{{ c.name }}</p>
                        <p class="text-xs text-gray-500">{{ c.email || c.phone }}</p>
                      </div>
                    </div>
                  </td>
                  <td>
                    <StatusBadge :label="tierMeta[c.vip_tier]?.label ?? c.vip_tier" :tone="tierMeta[c.vip_tier]?.tone ?? 'gray'" />
                  </td>
                  <td class="font-semibold text-gray-800 dark:text-white">{{ Number(c.loyalty_points || 0).toLocaleString('fr-FR') }} pts</td>
                  <td>
                    <div class="flex justify-end gap-1.5">
                      <ActionButton icon="plus" :label="`Ajouter ${Math.abs(points || 0)} pts`" variant="success" @click="adjust(c.id, Math.abs(points || 0))" />
                      <ActionButton icon="minus" :label="`Retirer ${Math.abs(points || 0)} pts`" variant="danger" @click="adjust(c.id, -Math.abs(points || 0))" />
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </TableState>
        <ListPager :page="page" :last-page="lastPage" :total="total" @change="load" />
      </div>
    </div>
  </AdminLayout>
</template>
