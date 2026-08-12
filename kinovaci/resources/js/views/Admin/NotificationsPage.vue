<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { api } from '@/api/client'

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

async function load() {
  loading.value = true
  error.value = ''
  try {
    const res = await api<any>('/admin/notifications')
    items.value = res.data || []
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
  await api(`/admin/notifications/${id}`, { method: 'DELETE' })
  await load()
}

onMounted(load)
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

      <div class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03] overflow-x-auto">
        <div v-if="loading" class="text-gray-500">Chargement…</div>
        <table v-else class="w-full text-sm min-w-[700px]">
          <thead>
            <tr class="border-b border-gray-100 text-left text-gray-500 dark:border-gray-800">
              <th class="py-2">Titre</th>
              <th>Catégorie</th>
              <th>Client</th>
              <th>Lu</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="n in items" :key="n.id" class="border-b border-gray-50 dark:border-gray-800">
              <td class="py-3">
                <div class="font-medium text-gray-800 dark:text-white">{{ n.title }}</div>
                <div class="text-xs text-gray-500 line-clamp-1">{{ n.message }}</div>
              </td>
              <td>{{ n.category }}</td>
              <td>{{ n.user?.name || (n.user_id ? `#${n.user_id}` : 'Broadcast') }}</td>
              <td>{{ n.is_read ? 'oui' : 'non' }}</td>
              <td class="text-right">
                <button class="text-error-500" @click="remove(n.id)">Suppr.</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </AdminLayout>
</template>
