<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { api } from '@/api/client'

interface UserItem {
  id: number
  name: string
  email: string
  phone: string | null
  role: 'admin' | 'customer'
  is_blocked: boolean
  address: string | null
  city: string | null
  loyalty_points: number
  vip_tier: 'standard' | 'gold' | 'platinum' | 'diamond'
  created_at: string
  orders_count?: number
}

const loading = ref(true)
const saving = ref(false)
const error = ref('')
const successMessage = ref('')

const users = ref<UserItem[]>([])
const pagination = reactive({
  currentPage: 1,
  lastPage: 1,
  total: 0,
})

const filters = reactive({
  q: '',
  role: '',
  status: '',
})

const showModal = ref(false)

const form = reactive({
  id: null as number | null,
  name: '',
  email: '',
  password: '',
  phone: '',
  address: '',
  city: '',
  role: 'customer' as 'admin' | 'customer',
  vip_tier: 'standard' as 'standard' | 'gold' | 'platinum' | 'diamond',
  loyalty_points: 0,
  is_blocked: false,
})

async function load(page = 1) {
  loading.value = true
  error.value = ''
  try {
    const params = new URLSearchParams()
    params.set('page', String(page))
    if (filters.q) params.set('q', filters.q)
    if (filters.role) params.set('role', filters.role)
    if (filters.status) params.set('status', filters.status)

    const res = await api<any>(`/admin/users?${params.toString()}`)
    users.value = res.data || []
    pagination.currentPage = res.current_page || 1
    pagination.lastPage = res.last_page || 1
    pagination.total = res.total || 0
  } catch (e: any) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

function openCreateModal() {
  resetForm()
  showModal.value = true
}

function editUser(u: UserItem) {
  form.id = u.id
  form.name = u.name
  form.email = u.email
  form.password = ''
  form.phone = u.phone || ''
  form.address = u.address || ''
  form.city = u.city || ''
  form.role = u.role
  form.vip_tier = u.vip_tier || 'standard'
  form.loyalty_points = u.loyalty_points || 0
  form.is_blocked = !!u.is_blocked
  showModal.value = true
}

function resetForm() {
  form.id = null
  form.name = ''
  form.email = ''
  form.password = ''
  form.phone = ''
  form.address = ''
  form.city = ''
  form.role = 'customer'
  form.vip_tier = 'standard'
  form.loyalty_points = 0
  form.is_blocked = false
}

function closeModal() {
  showModal.value = false
  resetForm()
}

async function save() {
  saving.value = true
  error.value = ''
  successMessage.value = ''
  try {
    const payload: any = {
      name: form.name,
      email: form.email,
      role: form.role,
      phone: form.phone || null,
      address: form.address || null,
      city: form.city || null,
      vip_tier: form.vip_tier,
      loyalty_points: Number(form.loyalty_points),
      is_blocked: form.is_blocked,
    }

    if (form.password) {
      payload.password = form.password
    }

    if (form.id) {
      const res = await api<any>(`/admin/users/${form.id}`, { method: 'PUT', json: payload })
      successMessage.value = res.message || 'Utilisateur mis à jour'
    } else {
      if (!form.password) {
        error.value = 'Le mot de passe est obligatoire lors de la création'
        saving.value = false
        return
      }
      const res = await api<any>('/admin/users', { method: 'POST', json: payload })
      successMessage.value = res.message || 'Utilisateur créé'
    }

    closeModal()
    await load(pagination.currentPage)
  } catch (e: any) {
    error.value = e.message
  } finally {
    saving.value = false
  }
}

async function toggleBlock(u: UserItem) {
  const action = u.is_blocked ? 'débloquer' : 'bloquer'
  if (!confirm(`Êtes-vous sûr de vouloir ${action} le compte de ${u.name} ?`)) return

  error.value = ''
  successMessage.value = ''
  try {
    const res = await api<any>(`/admin/users/${u.id}/toggle-block`, { method: 'POST' })
    successMessage.value = res.message
    await load(pagination.currentPage)
  } catch (e: any) {
    error.value = e.message
  }
}

async function removeUser(u: UserItem) {
  if (!confirm(`Supprimer définitivement l'utilisateur ${u.name} ? Cette action est irréversible.`)) return

  error.value = ''
  successMessage.value = ''
  try {
    const res = await api<any>(`/admin/users/${u.id}`, { method: 'DELETE' })
    successMessage.value = res.message || 'Utilisateur supprimé'
    await load(pagination.currentPage)
  } catch (e: any) {
    error.value = e.message
  }
}

function formatDate(d: string) {
  if (!d) return '—'
  return new Date(d).toLocaleDateString('fr-FR', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  })
}

onMounted(() => load(1))
</script>

<template>
  <AdminLayout>
    <div class="space-y-6">
      <!-- En-tête -->
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 class="text-2xl font-bold text-gray-900 dark:text-white">Gestion des Utilisateurs</h1>
          <p class="text-sm text-gray-500 mt-1">Gérez les comptes clients et administrateurs, bloquez ou débloquez les accès.</p>
        </div>
        <button
          @click="openCreateModal"
          class="inline-flex items-center justify-center gap-2 rounded-xl bg-brand-500 hover:bg-brand-600 text-white px-4 py-2.5 text-sm font-semibold transition-all shadow-md shadow-brand-500/20"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
          </svg>
          Nouvel Utilisateur
        </button>
      </div>

      <!-- Alerts -->
      <div v-if="error" class="rounded-xl border border-rose-200 bg-rose-50 p-4 text-sm text-rose-700 dark:border-rose-900/50 dark:bg-rose-950/30 dark:text-rose-400">
        {{ error }}
      </div>
      <div v-if="successMessage" class="rounded-xl border border-emerald-200 bg-emerald-50 p-4 text-sm text-emerald-700 dark:border-emerald-900/50 dark:bg-emerald-950/30 dark:text-emerald-400">
        {{ successMessage }}
      </div>

      <!-- Filtres et Recherche -->
      <div class="rounded-2xl border border-gray-200 bg-white p-4 dark:border-gray-800 dark:bg-white/[0.03] flex flex-col md:flex-row items-center gap-3">
        <div class="relative flex-1 w-full">
          <input
            v-model="filters.q"
            type="text"
            placeholder="Rechercher par nom, email ou téléphone..."
            class="w-full rounded-xl border border-gray-200 pl-10 pr-4 py-2.5 text-sm text-gray-900 placeholder-gray-400 focus:border-brand-500 focus:ring-1 focus:ring-brand-500 dark:border-gray-700 dark:bg-gray-900 dark:text-white"
            @keyup.enter="load(1)"
          />
          <svg class="w-5 h-5 text-gray-400 absolute left-3 top-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
          </svg>
        </div>

        <select
          v-model="filters.role"
          class="w-full md:w-44 rounded-xl border border-gray-200 px-3 py-2.5 text-sm text-gray-900 dark:border-gray-700 dark:bg-gray-900 dark:text-white"
          @change="load(1)"
        >
          <option value="">Tous les rôles</option>
          <option value="customer">Clients</option>
          <option value="admin">Administrateurs</option>
        </select>

        <select
          v-model="filters.status"
          class="w-full md:w-44 rounded-xl border border-gray-200 px-3 py-2.5 text-sm text-gray-900 dark:border-gray-700 dark:bg-gray-900 dark:text-white"
          @change="load(1)"
        >
          <option value="">Tous les statuts</option>
          <option value="active">Comptes Actifs</option>
          <option value="blocked">Comptes Bloqués</option>
        </select>

        <button
          @click="load(1)"
          class="w-full md:w-auto rounded-xl border border-gray-200 px-4 py-2.5 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-700 dark:text-gray-300 dark:hover:bg-gray-800"
        >
          Filtrer
        </button>
      </div>

      <!-- Tableau Utilisateurs -->
      <div class="rounded-2xl border border-gray-200 bg-white dark:border-gray-800 dark:bg-white/[0.03] overflow-hidden shadow-sm">
        <div v-if="loading" class="p-8 text-center text-gray-500">
          <div class="inline-block animate-spin rounded-full h-8 w-8 border-4 border-brand-500 border-t-transparent"></div>
          <p class="mt-2 text-sm">Chargement des utilisateurs...</p>
        </div>

        <div v-else-if="users.length === 0" class="p-8 text-center text-gray-500">
          Aucun utilisateur trouvé.
        </div>

        <div v-else class="overflow-x-auto">
          <table class="w-full text-left text-sm min-w-[850px]">
            <thead class="bg-gray-50 dark:bg-gray-800/50 text-xs uppercase font-semibold text-gray-500 dark:text-gray-400 border-b border-gray-100 dark:border-gray-800">
              <tr>
                <th class="py-3.5 px-5">Utilisateur</th>
                <th class="py-3.5 px-4">Rôle</th>
                <th class="py-3.5 px-4">Statut</th>
                <th class="py-3.5 px-4">VIP & Points</th>
                <th class="py-3.5 px-4">Commandes</th>
                <th class="py-3.5 px-4">Inscrit le</th>
                <th class="py-3.5 px-5 text-right">Actions</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100 dark:divide-gray-800">
              <tr v-for="u in users" :key="u.id" class="hover:bg-gray-50/50 dark:hover:bg-gray-800/30 transition-colors">
                <td class="py-4 px-5">
                  <div class="flex items-center gap-3">
                    <div class="w-10 h-10 rounded-full bg-brand-500/10 border border-brand-500/20 text-brand-600 dark:text-brand-400 font-bold flex items-center justify-center text-sm uppercase">
                      {{ u.name.charAt(0) }}
                    </div>
                    <div>
                      <div class="font-semibold text-gray-900 dark:text-white">{{ u.name }}</div>
                      <div class="text-xs text-gray-500 dark:text-gray-400">{{ u.email }}</div>
                      <div v-if="u.phone" class="text-xs text-gray-400">{{ u.phone }}</div>
                    </div>
                  </div>
                </td>

                <td class="py-4 px-4">
                  <span
                    :class="[
                      'inline-flex items-center px-2.5 py-1 rounded-lg text-xs font-semibold',
                      u.role === 'admin'
                        ? 'bg-amber-100 text-amber-800 dark:bg-amber-950/60 dark:text-amber-300 border border-amber-300/30'
                        : 'bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-300'
                    ]"
                  >
                    {{ u.role === 'admin' ? 'Administrateur' : 'Client' }}
                  </span>
                </td>

                <td class="py-4 px-4">
                  <span
                    :class="[
                      'inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold',
                      u.is_blocked
                        ? 'bg-rose-100 text-rose-800 dark:bg-rose-950/60 dark:text-rose-300 border border-rose-300/30'
                        : 'bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-300 border border-emerald-300/30'
                    ]"
                  >
                    <span :class="['w-1.5 h-1.5 rounded-full', u.is_blocked ? 'bg-rose-500' : 'bg-emerald-500']"></span>
                    {{ u.is_blocked ? 'Bloqué' : 'Actif' }}
                  </span>
                </td>

                <td class="py-4 px-4">
                  <div class="text-xs font-medium text-gray-800 dark:text-gray-200 uppercase tracking-wider">
                    {{ u.vip_tier || 'standard' }}
                  </div>
                  <div class="text-xs text-brand-500 font-semibold mt-0.5">
                    {{ u.loyalty_points || 0 }} pts
                  </div>
                </td>

                <td class="py-4 px-4 text-gray-700 dark:text-gray-300 font-medium">
                  {{ u.orders_count ?? 0 }}
                </td>

                <td class="py-4 px-4 text-xs text-gray-500 dark:text-gray-400 whitespace-nowrap">
                  {{ formatDate(u.created_at) }}
                </td>

                <td class="py-4 px-5 text-right whitespace-nowrap space-x-2">
                  <!-- Bouton Bloquer / Débloquer -->
                  <button
                    @click="toggleBlock(u)"
                    :title="u.is_blocked ? 'Débloquer le compte' : 'Bloquer le compte'"
                    :class="[
                      'px-3 py-1.5 rounded-lg text-xs font-semibold transition-all border',
                      u.is_blocked
                        ? 'bg-emerald-50 text-emerald-700 border-emerald-200 hover:bg-emerald-100 dark:bg-emerald-950/40 dark:text-emerald-300 dark:border-emerald-800'
                        : 'bg-rose-50 text-rose-700 border-rose-200 hover:bg-rose-100 dark:bg-rose-950/40 dark:text-rose-300 dark:border-rose-800'
                    ]"
                  >
                    {{ u.is_blocked ? 'Débloquer' : 'Bloquer' }}
                  </button>

                  <!-- Bouton Éditer -->
                  <button
                    @click="editUser(u)"
                    class="px-3 py-1.5 rounded-lg text-xs font-semibold bg-gray-100 text-gray-700 hover:bg-gray-200 dark:bg-gray-800 dark:text-gray-200 dark:hover:bg-gray-700 transition-colors"
                  >
                    Éditer
                  </button>

                  <!-- Bouton Supprimer -->
                  <button
                    @click="removeUser(u)"
                    class="px-3 py-1.5 rounded-lg text-xs font-semibold bg-red-500/10 text-red-600 hover:bg-red-500/20 dark:text-red-400 transition-colors"
                  >
                    Suppr.
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Pagination -->
        <div v-if="pagination.lastPage > 1" class="p-4 border-t border-gray-100 dark:border-gray-800 flex items-center justify-between">
          <div class="text-xs text-gray-500">
            Total : {{ pagination.total }} utilisateur(s)
          </div>
          <div class="flex gap-2">
            <button
              :disabled="pagination.currentPage <= 1"
              @click="load(pagination.currentPage - 1)"
              class="px-3 py-1.5 rounded-lg border border-gray-200 text-xs font-medium disabled:opacity-40 dark:border-gray-700 dark:text-gray-300"
            >
              Précédent
            </button>
            <span class="px-3 py-1.5 text-xs text-gray-600 dark:text-gray-400 font-semibold">
              {{ pagination.currentPage }} / {{ pagination.lastPage }}
            </span>
            <button
              :disabled="pagination.currentPage >= pagination.lastPage"
              @click="load(pagination.currentPage + 1)"
              class="px-3 py-1.5 rounded-lg border border-gray-200 text-xs font-medium disabled:opacity-40 dark:border-gray-700 dark:text-gray-300"
            >
              Suivant
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal Création / Édition -->
    <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4 overflow-y-auto">
      <div class="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-2xl max-w-lg w-full p-6 shadow-2xl space-y-5 my-8">
        <div class="flex items-center justify-between border-b border-gray-100 dark:border-gray-800 pb-4">
          <h3 class="text-lg font-bold text-gray-900 dark:text-white">
            {{ form.id ? 'Modifier l\'utilisateur' : 'Créer un nouvel utilisateur' }}
          </h3>
          <button @click="closeModal" class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 text-xl font-bold">
            &times;
          </button>
        </div>

        <form @submit.prevent="save" class="space-y-4">
          <div>
            <label class="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">Nom complet *</label>
            <input
              v-model="form.name"
              type="text"
              required
              class="w-full rounded-xl border border-gray-200 px-3.5 py-2 text-sm text-gray-900 dark:border-gray-700 dark:bg-gray-800 dark:text-white focus:border-brand-500 focus:ring-1 focus:ring-brand-500"
            />
          </div>

          <div>
            <label class="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">Adresse Email *</label>
            <input
              v-model="form.email"
              type="email"
              required
              class="w-full rounded-xl border border-gray-200 px-3.5 py-2 text-sm text-gray-900 dark:border-gray-700 dark:bg-gray-800 dark:text-white focus:border-brand-500 focus:ring-1 focus:ring-brand-500"
            />
          </div>

          <div>
            <label class="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
              Mot de passe {{ form.id ? '(Laisser vide pour ne pas modifier)' : '*' }}
            </label>
            <input
              v-model="form.password"
              type="password"
              :required="!form.id"
              class="w-full rounded-xl border border-gray-200 px-3.5 py-2 text-sm text-gray-900 dark:border-gray-700 dark:bg-gray-800 dark:text-white focus:border-brand-500 focus:ring-1 focus:ring-brand-500"
            />
          </div>

          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">Téléphone</label>
              <input
                v-model="form.phone"
                type="text"
                class="w-full rounded-xl border border-gray-200 px-3.5 py-2 text-sm text-gray-900 dark:border-gray-700 dark:bg-gray-800 dark:text-white focus:border-brand-500 focus:ring-1 focus:ring-brand-500"
              />
            </div>

            <div>
              <label class="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">Rôle *</label>
              <select
                v-model="form.role"
                required
                class="w-full rounded-xl border border-gray-200 px-3.5 py-2 text-sm text-gray-900 dark:border-gray-700 dark:bg-gray-800 dark:text-white focus:border-brand-500 focus:ring-1 focus:ring-brand-500"
              >
                <option value="customer">Client</option>
                <option value="admin">Administrateur</option>
              </select>
            </div>
          </div>

          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">Niveau VIP</label>
              <select
                v-model="form.vip_tier"
                class="w-full rounded-xl border border-gray-200 px-3.5 py-2 text-sm text-gray-900 dark:border-gray-700 dark:bg-gray-800 dark:text-white focus:border-brand-500 focus:ring-1 focus:ring-brand-500 uppercase"
              >
                <option value="standard">STANDARD</option>
                <option value="gold">GOLD</option>
                <option value="platinum">PLATINUM</option>
                <option value="diamond">DIAMOND</option>
              </select>
            </div>

            <div>
              <label class="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">Points Fidélité</label>
              <input
                v-model.number="form.loyalty_points"
                type="number"
                min="0"
                class="w-full rounded-xl border border-gray-200 px-3.5 py-2 text-sm text-gray-900 dark:border-gray-700 dark:bg-gray-800 dark:text-white focus:border-brand-500 focus:ring-1 focus:ring-brand-500"
              />
            </div>
          </div>

          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">Adresse</label>
              <input
                v-model="form.address"
                type="text"
                class="w-full rounded-xl border border-gray-200 px-3.5 py-2 text-sm text-gray-900 dark:border-gray-700 dark:bg-gray-800 dark:text-white focus:border-brand-500 focus:ring-1 focus:ring-brand-500"
              />
            </div>

            <div>
              <label class="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">Ville</label>
              <input
                v-model="form.city"
                type="text"
                class="w-full rounded-xl border border-gray-200 px-3.5 py-2 text-sm text-gray-900 dark:border-gray-700 dark:bg-gray-800 dark:text-white focus:border-brand-500 focus:ring-1 focus:ring-brand-500"
              />
            </div>
          </div>

          <div class="pt-2">
            <label class="flex items-center gap-2 cursor-pointer">
              <input
                v-model="form.is_blocked"
                type="checkbox"
                class="w-4 h-4 text-brand-500 rounded border-gray-300 focus:ring-brand-500"
              />
              <span class="text-sm font-semibold text-rose-600 dark:text-rose-400">Bloquer le compte immédiatement</span>
            </label>
          </div>

          <div class="flex items-center justify-end gap-3 pt-4 border-t border-gray-100 dark:border-gray-800">
            <button
              type="button"
              @click="closeModal"
              class="px-4 py-2 rounded-xl border border-gray-200 text-xs font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-700 dark:text-gray-300 dark:hover:bg-gray-800"
            >
              Annuler
            </button>
            <button
              type="submit"
              :disabled="saving"
              class="px-5 py-2 rounded-xl bg-brand-500 hover:bg-brand-600 text-white text-xs font-semibold transition-all shadow-md shadow-brand-500/20 disabled:opacity-50"
            >
              {{ saving ? 'Enregistrement...' : 'Enregistrer' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </AdminLayout>
</template>
