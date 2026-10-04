<script setup lang="ts">
import { onMounted, ref } from 'vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { api } from '@/api/client'
import ListPager from '@/components/admin/ListPager.vue'
import ActionButton from '@/components/admin/ActionButton.vue'
import StatusBadge from '@/components/admin/StatusBadge.vue'
import TableState from '@/components/admin/TableState.vue'
import FormField from '@/components/admin/FormField.vue'

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
  if (!delta) {
    error.value = 'Indiquez un nombre de points supérieur à 0.'
    return
  }
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

      <div class="admin-card">
        <div class="admin-card-header">
          <div>
            <h2 class="font-semibold text-gray-800 dark:text-white">Ajuster des points</h2>
            <p class="text-sm text-gray-500 dark:text-gray-400">
              Réglez le nombre et le motif ici, puis cliquez sur + (ajouter) ou − (retirer) sur la ligne du client.
            </p>
          </div>
        </div>
        <div class="grid grid-cols-1 gap-4 p-5 md:grid-cols-3">
          <FormField label="Nombre de points" for="l-points" hint="Le solde d’un client ne descend jamais sous 0.">
            <div class="relative">
              <input id="l-points" v-model.number="points" type="number" min="1" max="1000000" class="admin-input pr-12" />
              <span class="pointer-events-none absolute inset-y-0 right-3.5 flex items-center text-xs font-medium text-gray-400">pts</span>
            </div>
          </FormField>
          <FormField label="Motif" for="l-note" hint="Visible dans l’historique de points du client." class="md:col-span-2">
            <input id="l-note" v-model="note" maxlength="255" placeholder="Ex. Geste commercial, concours Instagram…" class="admin-input" />
          </FormField>
        </div>
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
