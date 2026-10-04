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

        <div class="admin-card self-start">
          <div class="admin-card-header">
            <h2 class="font-semibold text-gray-800 dark:text-white">Détail du message</h2>
            <StatusBadge v-if="selected" :label="statusMeta[selected.status]?.label ?? selected.status" :tone="statusMeta[selected.status]?.tone ?? 'gray'" />
          </div>
          <div v-if="!selected" class="px-5 py-14 text-center text-sm text-gray-500">Cliquez sur un message pour l’afficher ici.</div>
          <div v-else class="space-y-4 p-5 text-sm">
            <div class="space-y-1">
              <p class="font-semibold text-gray-800 dark:text-white">{{ selected.subject }}</p>
              <p class="text-xs text-gray-500">{{ formatDate(selected.created_at) }}</p>
            </div>
            <dl class="grid grid-cols-[auto_1fr] gap-x-4 gap-y-1.5 rounded-xl bg-gray-50 p-3.5 dark:bg-white/5">
              <dt class="text-gray-500">Nom</dt>
              <dd class="text-gray-800 dark:text-white">{{ selected.name }}</dd>
              <dt class="text-gray-500">E-mail</dt>
              <dd class="truncate"><a :href="`mailto:${selected.email}`" class="text-brand-500 hover:underline dark:text-brand-300">{{ selected.email }}</a></dd>
              <dt class="text-gray-500">Téléphone</dt>
              <dd>
                <a v-if="selected.phone" :href="`tel:${selected.phone}`" class="text-brand-500 hover:underline dark:text-brand-300">{{ selected.phone }}</a>
                <span v-else class="text-gray-400">—</span>
              </dd>
            </dl>
            <div>
              <p class="admin-section-title mb-1.5">Message du client</p>
              <p class="whitespace-pre-wrap rounded-xl border border-gray-100 p-3.5 text-gray-700 dark:border-gray-800 dark:text-gray-300">{{ selected.message }}</p>
            </div>
            <FormField label="Votre réponse" for="m-reply" hint="Enregistrée avec le message ; contactez aussi le client par téléphone ou e-mail si besoin.">
              <textarea id="m-reply" v-model="reply" rows="5" maxlength="5000" placeholder="Bonjour, merci pour votre message…" class="admin-input" />
            </FormField>
            <div class="flex flex-wrap gap-2">
              <button type="button" class="admin-btn-primary" :disabled="!reply.trim()" @click="saveReply">Enregistrer la réponse</button>
              <button v-if="selected.status !== 'closed'" type="button" class="admin-btn-secondary" @click="closeMsg">Clôturer</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>
