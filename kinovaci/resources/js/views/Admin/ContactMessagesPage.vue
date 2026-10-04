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
const messages = ref<any[]>([])
const selected = ref<any | null>(null)
const reply = ref('')

const page = ref(1)
const lastPage = ref(1)
const total = ref(0)

async function load(p = page.value) {
  loading.value = true
  error.value = ''
  try {
    const res = await api<any>(`/admin/contact-messages?page=${p}&per_page=10`)
    if (!res.data?.length && p > 1) return await load(p - 1)
    messages.value = res.data || []
    page.value = res.current_page || 1
    lastPage.value = res.last_page || 1
    total.value = res.total || 0
  } catch (e: any) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

async function open(msg: any) {
  error.value = ''
  try {
    const res = await api<{ data: any }>(`/admin/contact-messages/${msg.id}`)
    selected.value = res.data
    reply.value = res.data.admin_reply || ''
    await load()
  } catch (e: any) {
    error.value = e.message
  }
}

async function saveReply() {
  if (!selected.value) return
  error.value = ''
  try {
    const res = await api<{ data: any }>(`/admin/contact-messages/${selected.value.id}`, {
      method: 'PUT',
      json: { admin_reply: reply.value, status: 'replied' },
    })
    selected.value = res.data
    await load()
  } catch (e: any) {
    error.value = e.message
  }
}

async function closeMsg() {
  if (!selected.value) return
  error.value = ''
  try {
    const res = await api<{ data: any }>(`/admin/contact-messages/${selected.value.id}`, {
      method: 'PUT',
      json: { status: 'closed' },
    })
    selected.value = res.data
    await load()
  } catch (e: any) {
    error.value = e.message
  }
}

const statusMeta: Record<string, { label: string; tone: 'info' | 'warning' | 'success' | 'gray' }> = {
  new: { label: 'Nouveau', tone: 'info' },
  read: { label: 'Lu', tone: 'warning' },
  replied: { label: 'Répondu', tone: 'success' },
  closed: { label: 'Clôturé', tone: 'gray' },
}

const formatDate = (iso: string) =>
  new Intl.DateTimeFormat('fr-FR', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' }).format(new Date(iso))

onMounted(() => load())
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
        <div class="admin-card self-start xl:col-span-2">
          <div class="admin-card-header">
            <h2 class="font-semibold text-gray-800 dark:text-white">Boîte de réception</h2>
          </div>
          <TableState :loading="loading" :empty="!messages.length" empty-text="Aucun message pour le moment">
            <div class="overflow-x-auto">
              <table class="admin-table min-w-[620px]">
                <thead>
                  <tr>
                    <th>Message</th>
                    <th>Client</th>
                    <th>Statut</th>
                    <th class="text-right">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  <tr
                    v-for="m in messages"
                    :key="m.id"
                    class="cursor-pointer"
                    :class="{ 'is-selected': selected?.id === m.id }"
                    @click="open(m)"
                  >
                    <td>
                      <p :class="['text-gray-800 dark:text-white', m.status === 'new' ? 'font-semibold' : 'font-medium']">{{ m.subject }}</p>
                      <p class="text-xs text-gray-500">{{ formatDate(m.created_at) }}</p>
                    </td>
                    <td>
                      <p class="text-gray-800 dark:text-white">{{ m.name }}</p>
                      <p class="text-xs text-gray-500">{{ m.email }}</p>
                    </td>
                    <td>
                      <StatusBadge :label="statusMeta[m.status]?.label ?? m.status" :tone="statusMeta[m.status]?.tone ?? 'gray'" />
                    </td>
                    <td>
                      <div class="flex justify-end">
                        <ActionButton icon="eye" label="Ouvrir" variant="brand" @click.stop="open(m)" />
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </TableState>
          <ListPager :page="page" :last-page="lastPage" :total="total" @change="load" />
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
