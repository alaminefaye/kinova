<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { api } from '@/api/client'
import ListPager from '@/components/admin/ListPager.vue'
import ActionButton from '@/components/admin/ActionButton.vue'
import StatusBadge from '@/components/admin/StatusBadge.vue'
import TableState from '@/components/admin/TableState.vue'

const loading = ref(true)
const sending = ref(false)
const error = ref('')
const items = ref<any[]>([])
const form = reactive({
  title: '',
  message: '',
  category: 'promo',
  broadcast: true,
  user_id: '' as string | number,
})

const page = ref(1)
const lastPage = ref(1)
const total = ref(0)

async function load(p = page.value) {
  loading.value = true
  error.value = ''
  try {
    const res = await api<any>(`/admin/notifications?page=${p}&per_page=10`)
    if (!res.data?.length && p > 1) return await load(p - 1)
    items.value = res.data || []
    page.value = res.current_page || 1
    lastPage.value = res.last_page || 1
    total.value = res.total || 0
  } catch (e: any) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

async function send() {
  sending.value = true
  error.value = ''
  try {
    await api('/admin/notifications', {
      method: 'POST',
      json: {
        title: form.title,
        message: form.message,
        category: form.category,
        broadcast: form.broadcast,
        user_id: form.broadcast ? null : Number(form.user_id),
      },
    })
    form.title = ''
    form.message = ''
    await load()
  } catch (e: any) {
    error.value = e.message
  } finally {
    sending.value = false
  }
}

async function remove(id: number) {
  if (!confirm('Supprimer ?')) return
  error.value = ''
  try {
    await api(`/admin/notifications/${id}`, { method: 'DELETE' })
    await load()
  } catch (e: any) {
    error.value = e.message
  }
}

const categoryMeta: Record<string, { label: string; tone: 'brand' | 'info' | 'warning' | 'gray' }> = {
  promo: { label: 'Promo', tone: 'brand' },
  order: { label: 'Commande', tone: 'info' },
  vip: { label: 'VIP', tone: 'warning' },
  system: { label: 'Système', tone: 'gray' },
}

const formatDate = (iso: string) =>
  new Intl.DateTimeFormat('fr-FR', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' }).format(new Date(iso))

onMounted(() => load())
</script>

<template>
  <AdminLayout>
    <div class="space-y-6">
      <div>
        <h1 class="text-2xl font-semibold text-gray-800 dark:text-white">Notifications</h1>
        <p class="text-sm text-gray-500 mt-1">Envoyer et consulter les alertes clients</p>
      </div>

      <div v-if="error" class="rounded-lg border border-error-200 bg-error-50 px-4 py-3 text-error-700">{{ error }}</div>

      <form class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03] space-y-3" @submit.prevent="send">
        <h2 class="font-semibold text-gray-800 dark:text-white">Nouvelle notification</h2>
        <input v-model="form.title" required placeholder="Titre" class="w-full rounded-lg border border-gray-200 px-3 py-2.5 dark:border-gray-700 dark:bg-gray-900" />
        <textarea v-model="form.message" required rows="3" placeholder="Message" class="w-full rounded-lg border border-gray-200 px-3 py-2.5 dark:border-gray-700 dark:bg-gray-900" />
        <div class="grid grid-cols-1 md:grid-cols-3 gap-3">
          <select v-model="form.category" class="rounded-lg border border-gray-200 px-3 py-2.5 dark:border-gray-700 dark:bg-gray-900">
            <option value="promo">promo</option>
            <option value="order">order</option>
            <option value="vip">vip</option>
            <option value="system">system</option>
          </select>
          <label class="flex items-center gap-2 text-sm">
            <input v-model="form.broadcast" type="checkbox" /> Diffuser à tous les clients
          </label>
          <input
            v-if="!form.broadcast"
            v-model="form.user_id"
            type="number"
            required
            placeholder="User ID"
            class="rounded-lg border border-gray-200 px-3 py-2.5 dark:border-gray-700 dark:bg-gray-900"
          />
        </div>
        <button type="submit" class="rounded-lg bg-brand-500 px-4 py-2.5 text-sm font-medium text-white" :disabled="sending">
          {{ sending ? '…' : 'Envoyer' }}
        </button>
      </form>

      <div class="admin-card">
        <div class="admin-card-header">
          <h2 class="font-semibold text-gray-800 dark:text-white">Historique des notifications</h2>
        </div>
        <TableState :loading="loading" :empty="!items.length" empty-text="Aucune notification envoyée">
          <div class="overflow-x-auto">
            <table class="admin-table min-w-[720px]">
              <thead>
                <tr>
                  <th>Notification</th>
                  <th>Catégorie</th>
                  <th>Destinataire</th>
                  <th>Lecture</th>
                  <th class="text-right">Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="n in items" :key="n.id">
                  <td class="max-w-md">
                    <p class="font-medium text-gray-800 dark:text-white">{{ n.title }}</p>
                    <p class="line-clamp-1 text-xs text-gray-500">{{ n.message }}</p>
                    <p class="mt-0.5 text-[11px] text-gray-400">{{ formatDate(n.created_at) }}</p>
                  </td>
                  <td>
                    <StatusBadge :label="categoryMeta[n.category]?.label ?? n.category" :tone="categoryMeta[n.category]?.tone ?? 'gray'" :dot="false" />
                  </td>
                  <td>{{ n.user?.name || (n.user_id ? `#${n.user_id}` : 'Tous les clients') }}</td>
                  <td>
                    <StatusBadge v-if="!n.user_id" label="Diffusion" tone="gray" :dot="false" />
                    <StatusBadge v-else :label="n.is_read ? 'Lue' : 'Non lue'" :tone="n.is_read ? 'success' : 'warning'" />
                  </td>
                  <td>
                    <div class="flex justify-end">
                      <ActionButton icon="trash" label="Supprimer" variant="danger" @click="remove(n.id)" />
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
