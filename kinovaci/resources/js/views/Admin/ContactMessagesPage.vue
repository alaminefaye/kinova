<script setup lang="ts">
import { onMounted, ref } from 'vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { api } from '@/api/client'

const loading = ref(true)
const error = ref('')
const messages = ref<any[]>([])
const selected = ref<any | null>(null)
const reply = ref('')

async function load() {
  loading.value = true
  error.value = ''
  try {
    const res = await api<any>('/admin/contact-messages')
    messages.value = res.data || []
  } catch (e: any) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

async function open(msg: any) {
  const res = await api<{ data: any }>(`/admin/contact-messages/${msg.id}`)
  selected.value = res.data
  reply.value = res.data.admin_reply || ''
  await load()
}

async function saveReply() {
  if (!selected.value) return
  const res = await api<{ data: any }>(`/admin/contact-messages/${selected.value.id}`, {
    method: 'PUT',
    json: { admin_reply: reply.value, status: 'replied' },
  })
  selected.value = res.data
  await load()
}

async function closeMsg() {
  if (!selected.value) return
  const res = await api<{ data: any }>(`/admin/contact-messages/${selected.value.id}`, {
    method: 'PUT',
    json: { status: 'closed' },
  })
  selected.value = res.data
  await load()
}

onMounted(load)
</script>

<template>
  <AdminLayout>
    <div class="space-y-6">
      <div>
        <h1 class="text-2xl font-semibold text-gray-800 dark:text-white">Messages contact</h1>
        <p class="text-sm text-gray-500 mt-1">Demandes d’aide depuis l’app / site</p>
      </div>

      <div v-if="error" class="rounded-lg border border-error-200 bg-error-50 px-4 py-3 text-error-700">{{ error }}</div>

      <div class="grid grid-cols-1 gap-6 xl:grid-cols-3">
        <div class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03] xl:col-span-2 overflow-x-auto">
          <div v-if="loading" class="text-gray-500">Chargement…</div>
          <table v-else class="w-full text-sm min-w-[640px]">
            <thead>
              <tr class="border-b border-gray-100 text-left text-gray-500 dark:border-gray-800">
                <th class="py-2">Sujet</th>
                <th>Client</th>
                <th>Statut</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="m in messages" :key="m.id" class="border-b border-gray-50 dark:border-gray-800">
                <td class="py-3 font-medium text-gray-800 dark:text-white">{{ m.subject }}</td>
                <td>{{ m.name }}</td>
                <td>
                  <span class="rounded-full bg-brand-50 px-2 py-1 text-xs text-brand-600">{{ m.status }}</span>
                </td>
                <td class="text-right">
                  <button class="text-brand-500" @click="open(m)">Ouvrir</button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03] space-y-3 text-sm">
          <h2 class="font-semibold text-gray-800 dark:text-white">Détail</h2>
          <div v-if="!selected" class="text-gray-500">Sélectionnez un message</div>
          <template v-else>
            <p><span class="text-gray-500">De</span> {{ selected.name }} ({{ selected.email }})</p>
            <p><span class="text-gray-500">Tél.</span> {{ selected.phone || '—' }}</p>
            <p class="whitespace-pre-wrap">{{ selected.message }}</p>
            <textarea v-model="reply" rows="4" placeholder="Réponse admin" class="w-full rounded-lg border border-gray-200 px-3 py-2.5 dark:border-gray-700 dark:bg-gray-900" />
            <div class="flex gap-2">
              <button class="rounded-lg bg-brand-500 px-4 py-2 text-white" @click="saveReply">Enregistrer réponse</button>
              <button class="rounded-lg border border-gray-200 px-4 py-2" @click="closeMsg">Clôturer</button>
            </div>
          </template>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>
