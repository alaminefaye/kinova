<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { api } from '@/api/client'
import ListPager from '@/components/admin/ListPager.vue'
import ActionButton from '@/components/admin/ActionButton.vue'
import StatusBadge from '@/components/admin/StatusBadge.vue'
import TableState from '@/components/admin/TableState.vue'
import FormField from '@/components/admin/FormField.vue'

const loading = ref(true)
const sending = ref(false)
const error = ref('')
const success = ref('')
const clientQuery = ref('')
const clientResults = ref<any[]>([])
const selectedClient = ref<any | null>(null)
let searchTimer: ReturnType<typeof setTimeout> | undefined
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

function searchClients() {
  clearTimeout(searchTimer)
  const q = clientQuery.value.trim()
  if (q.length < 2) {
    clientResults.value = []
    return
  }
  searchTimer = setTimeout(async () => {
    try {
      const res = await api<any>(`/admin/users?role=customer&per_page=6&q=${encodeURIComponent(q)}`)
      clientResults.value = res.data || []
    } catch {
      clientResults.value = []
    }
  }, 300)
}

function pickClient(client: any) {
  selectedClient.value = client
  form.user_id = client.id
  clientQuery.value = ''
  clientResults.value = []
}

function clearClient() {
  selectedClient.value = null
  form.user_id = ''
}

async function send() {
  error.value = ''
  if (!form.broadcast && !form.user_id) {
    error.value = 'Choisissez le client qui doit recevoir la notification.'
    return
  }
  if (form.broadcast && !confirm('Envoyer cette notification à tous les clients ?')) return
  sending.value = true
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
    success.value = form.broadcast ? 'Notification envoyée à tous les clients.' : `Notification envoyée à ${selectedClient.value?.name ?? 'ce client'}.`
    setTimeout(() => (success.value = ''), 4000)
    form.title = ''
    form.message = ''
    await load(1)
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
      <div v-if="success" class="rounded-lg border border-success-200 bg-success-50 px-4 py-3 text-sm text-success-700 dark:border-success-500/30 dark:bg-success-500/10 dark:text-success-400">
        {{ success }}
      </div>

      <form class="admin-card" @submit.prevent="send">
        <div class="admin-card-header">
          <div>
            <h2 class="font-semibold text-gray-800 dark:text-white">Envoyer une notification</h2>
            <p class="text-sm text-gray-500 dark:text-gray-400">Le message arrive dans l’app (cloche) et en notification sur le téléphone.</p>
          </div>
        </div>

        <div class="grid grid-cols-1 gap-6 p-5 lg:grid-cols-5">
          <div class="space-y-5 lg:col-span-3">
            <FormField label="Titre" for="n-title" required>
              <input id="n-title" v-model="form.title" required maxlength="120" placeholder="Ex. -20 % sur toute la collection Beauté" class="admin-input" />
            </FormField>
            <FormField label="Message" for="n-message" required :hint="`${form.message.length} / 1000 caractères`">
              <textarea id="n-message" v-model="form.message" required rows="4" maxlength="1000" placeholder="Ex. Profitez-en jusqu’à dimanche, livraison payée à réception." class="admin-input" />
            </FormField>
            <FormField label="Type de notification" for="n-category" hint="Sert à classer la notification et à choisir son icône dans l’app.">
              <select id="n-category" v-model="form.category" class="admin-input">
                <option value="promo">Promotion</option>
                <option value="order">Commande</option>
                <option value="vip">Fidélité VIP</option>
                <option value="system">Information</option>
              </select>
            </FormField>
          </div>

          <div class="space-y-5 lg:col-span-2">
            <div class="space-y-2">
              <p class="text-sm font-medium text-gray-700 dark:text-gray-300">Destinataires <span class="text-error-500">*</span></p>
              <div class="grid grid-cols-2 gap-2">
                <button
                  v-for="opt in [{ v: true, t: 'Tous les clients', d: 'Diffusion générale' }, { v: false, t: 'Un client', d: 'Message personnel' }]"
                  :key="String(opt.v)"
                  type="button"
                  :class="[
                    'rounded-xl border px-3 py-2.5 text-left transition',
                    form.broadcast === opt.v ? 'border-brand-500 bg-brand-25 ring-1 ring-brand-500/30 dark:bg-white/5' : 'border-gray-200 hover:border-gray-300 dark:border-gray-700',
                  ]"
                  @click="form.broadcast = opt.v"
                >
                  <span class="block text-sm font-medium text-gray-800 dark:text-white">{{ opt.t }}</span>
                  <span class="block text-xs text-gray-500">{{ opt.d }}</span>
                </button>
              </div>
            </div>

            <FormField v-if="!form.broadcast" label="Client" for="n-client" required hint="Tapez au moins 2 lettres du nom, de l’e-mail ou du téléphone.">
              <div v-if="selectedClient" class="flex items-center justify-between gap-3 rounded-lg border border-brand-200 bg-brand-25 px-3.5 py-2.5 dark:border-gray-700 dark:bg-white/5">
                <div class="min-w-0">
                  <p class="truncate text-sm font-medium text-gray-800 dark:text-white">{{ selectedClient.name }}</p>
                  <p class="truncate text-xs text-gray-500">{{ selectedClient.email || selectedClient.phone }}</p>
                </div>
                <button type="button" class="text-xs font-medium text-error-600 hover:underline" @click="clearClient">Changer</button>
              </div>
              <div v-else class="relative">
                <input id="n-client" v-model="clientQuery" type="search" autocomplete="off" placeholder="Rechercher un client…" class="admin-input" @input="searchClients" />
                <ul
                  v-if="clientResults.length"
                  class="absolute z-20 mt-1 max-h-64 w-full overflow-auto rounded-lg border border-gray-200 bg-white py-1 shadow-theme-lg dark:border-gray-700 dark:bg-gray-900"
                >
                  <li v-for="c in clientResults" :key="c.id">
                    <button type="button" class="w-full px-3.5 py-2 text-left hover:bg-gray-50 dark:hover:bg-white/5" @click="pickClient(c)">
                      <span class="block text-sm text-gray-800 dark:text-white">{{ c.name }}</span>
                      <span class="block text-xs text-gray-500">{{ c.email || c.phone }}</span>
                    </button>
                  </li>
                </ul>
              </div>
            </FormField>

            <div>
              <p class="admin-section-title mb-2">Aperçu sur le téléphone</p>
              <div class="flex gap-3 rounded-2xl bg-gray-100 p-3.5 dark:bg-gray-800">
                <span class="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-brand-500 text-xs font-bold text-white">K</span>
                <div class="min-w-0">
                  <p class="text-xs text-gray-500">KINOVA · maintenant</p>
                  <p class="truncate text-sm font-semibold text-gray-800 dark:text-white">{{ form.title || 'Titre de la notification' }}</p>
                  <p class="line-clamp-2 text-sm text-gray-600 dark:text-gray-300">{{ form.message || 'Votre message apparaîtra ici.' }}</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="flex justify-end border-t border-gray-100 px-5 py-4 dark:border-gray-800">
          <button type="submit" class="admin-btn-primary" :disabled="sending">
            {{ sending ? 'Envoi…' : form.broadcast ? 'Envoyer à tous les clients' : 'Envoyer au client' }}
          </button>
        </div>
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
