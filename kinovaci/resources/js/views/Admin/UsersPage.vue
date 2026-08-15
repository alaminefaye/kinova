<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { api } from '@/api/client'

interface RoleItem {
  id: number
  name: string
  users_count: number
  permissions: string[]
}

interface UserItem {
  id: number
  name: string
  email: string
  phone: string | null
  role: string
  roles?: string[]
  permissions?: string[]
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
const availableRoles = ref<RoleItem[]>([])

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
  roles: ['customer'] as string[],
  vip_tier: 'standard' as 'standard' | 'gold' | 'platinum' | 'diamond',
  loyalty_points: 0,
  is_blocked: false,
})

const roleBadgeColors: Record<string, string> = {
  'super-admin': 'bg-amber-500/15 text-amber-600 border border-amber-500/30 dark:bg-amber-500/10 dark:text-amber-400',
  'admin': 'bg-blue-500/15 text-blue-600 border border-blue-500/30 dark:bg-blue-500/10 dark:text-blue-400',
  'manager': 'bg-emerald-500/15 text-emerald-600 border border-emerald-500/30 dark:bg-emerald-500/10 dark:text-emerald-400',
  'support': 'bg-purple-500/15 text-purple-600 border border-purple-500/30 dark:bg-purple-500/10 dark:text-purple-400',
  'customer': 'bg-gray-500/15 text-gray-600 border border-gray-500/30 dark:bg-gray-500/10 dark:text-gray-400',
}

async function loadRoles() {
  try {
    const res = await api<RoleItem[]>('/admin/roles')
    availableRoles.value = res || []
  } catch {
    /* ignore */
  }
}

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
  form.roles = u.roles && u.roles.length ? [...u.roles] : [u.role || 'customer']
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
  form.roles = ['customer']
  form.vip_tier = 'standard'
  form.loyalty_points = 0
  form.is_blocked = false
}

function closeModal() {
  showModal.value = false
  resetForm()
}

function toggleFormRole(roleName: string) {
  const idx = form.roles.indexOf(roleName)
  if (idx >= 0) {
    if (form.roles.length > 1) {
      form.roles.splice(idx, 1)
    }
  } else {
    form.roles.push(roleName)
  }
}

async function save() {
  saving.value = true
  error.value = ''
  successMessage.value = ''
  try {
    const payload: any = {
      name: form.name,
      email: form.email,
      roles: form.roles,
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
    setTimeout(() => (successMessage.value = ''), 3000)
  } catch (e: any) {
    error.value = e.message
  } finally {
    saving.value = false
  }
}

async function toggleBlockUser(u: UserItem) {
  try {
    const res = await api<any>(`/admin/users/${u.id}/toggle-block`, { method: 'POST' })
    u.is_blocked = !u.is_blocked
    successMessage.value = res.message
    setTimeout(() => (successMessage.value = ''), 3000)
  } catch (e: any) {
    error.value = e.message
  }
}

async function deleteUser(u: UserItem) {
  if (!confirm(`Supprimer définitivement le compte de "${u.name}" ?`)) return
  try {
    await api(`/admin/users/${u.id}`, { method: 'DELETE' })
    successMessage.value = 'Utilisateur supprimé'
    await load(pagination.currentPage)
    setTimeout(() => (successMessage.value = ''), 3000)
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

onMounted(() => {
  load()
  loadRoles()
})
</script>

<template>
  <AdminLayout>
    <div class="p-4 sm:p-6 lg:p-8 max-w-7xl mx-auto space-y-6">
      <!-- En-tête -->
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 class="text-2xl font-bold tracking-tight text-gray-900 dark:text-white flex items-center gap-3">
            <span class="p-2 rounded-xl bg-amber-500/10 text-amber-600 dark:text-amber-400">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
              </svg>
            </span>
            Gestion des Utilisateurs
          </h1>
          <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
            Gérez les comptes clients et administrateurs, attribuez les rôles et permissions Spatie.
          </p>
        </div>

        <div class="flex items-center gap-2">
          <RouterLink
            to="/roles"
            class="inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-200 font-medium hover:bg-gray-50 dark:hover:bg-gray-700 transition shadow-sm text-sm"
          >
            <svg class="w-4 h-4 text-amber-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
            </svg>
            Gérer les Rôles
          </RouterLink>

          <button
            @click="openCreateModal"
            class="inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-gray-900 dark:bg-white text-white dark:text-gray-900 font-medium hover:bg-gray-800 dark:hover:bg-gray-100 transition shadow-sm text-sm"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
            Nouvel Utilisateur
          </button>
        </div>
      </div>

      <!-- Messages Flash -->
      <div v-if="successMessage" class="p-4 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-600 dark:text-emerald-400 flex items-center gap-3">
        <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
        </svg>
        <span class="text-sm font-medium">{{ successMessage }}</span>
      </div>

      <div v-if="error" class="p-4 rounded-xl bg-red-500/10 border border-red-500/20 text-red-600 dark:text-red-400 flex items-center gap-3">
        <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <span class="text-sm font-medium">{{ error }}</span>
      </div>

      <!-- Filtres -->
      <div class="p-4 bg-white dark:bg-gray-800 rounded-2xl border border-gray-200 dark:border-gray-700 shadow-sm flex flex-col sm:flex-row gap-3">
        <div class="relative flex-1">
          <input
            v-model="filters.q"
            @keyup.enter="load(1)"
            type="text"
            placeholder="Rechercher par nom, email ou téléphone..."
            class="w-full pl-10 pr-4 py-2.5 rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-900 text-gray-900 dark:text-white text-sm focus:ring-2 focus:ring-amber-500/20 focus:border-amber-500 outline-none"
          />
          <svg class="w-4 h-4 text-gray-400 absolute left-3.5 top-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
        </div>

        <select
          v-model="filters.role"
          @change="load(1)"
          class="px-3 py-2.5 rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-900 text-gray-900 dark:text-white text-sm outline-none"
        >
          <option value="">Tous les rôles</option>
          <option v-for="r in availableRoles" :key="r.id" :value="r.name">
            {{ r.name }}
          </option>
        </select>

        <select
          v-model="filters.status"
          @change="load(1)"
          class="px-3 py-2.5 rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-900 text-gray-900 dark:text-white text-sm outline-none"
        >
          <option value="">Tous les statuts</option>
          <option value="active">Actif</option>
          <option value="blocked">Bloqué</option>
        </select>

        <button
          @click="load(1)"
          class="px-4 py-2.5 rounded-xl bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-200 text-sm font-medium hover:bg-gray-200 dark:hover:bg-gray-600 transition"
        >
          Filtrer
        </button>
      </div>

      <!-- Tableau des Utilisateurs -->
      <div class="bg-white dark:bg-gray-800 rounded-2xl border border-gray-200 dark:border-gray-700 shadow-sm overflow-hidden">
        <div v-if="loading" class="p-12 text-center text-gray-500 dark:text-gray-400">
          <svg class="animate-spin h-8 w-8 mx-auto text-amber-500" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
          </svg>
          <p class="mt-3 text-sm">Chargement des utilisateurs...</p>
        </div>

        <div v-else class="overflow-x-auto">
          <table class="w-full text-left border-collapse">
            <thead>
              <tr class="border-b border-gray-100 dark:border-gray-700/60 bg-gray-50/50 dark:bg-gray-800/50 text-xs uppercase tracking-wider text-gray-500 dark:text-gray-400">
                <th class="py-4 px-6 font-semibold">Utilisateur</th>
                <th class="py-4 px-6 font-semibold">Rôle(s) Spatie</th>
                <th class="py-4 px-6 font-semibold">Statut</th>
                <th class="py-4 px-6 font-semibold">VIP & Points</th>
                <th class="py-4 px-6 font-semibold">Commandes</th>
                <th class="py-4 px-6 font-semibold">Inscrit le</th>
                <th class="py-4 px-6 font-semibold text-right">Actions</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100 dark:divide-gray-700/60 text-sm">
              <tr
                v-for="u in users"
                :key="u.id"
                class="hover:bg-gray-50/50 dark:hover:bg-gray-700/30 transition-colors"
              >
                <!-- Infos Utilisateur -->
                <td class="py-4 px-6">
                  <div class="flex items-center gap-3">
                    <div class="w-10 h-10 rounded-full bg-amber-500/10 border border-amber-500/20 text-amber-700 dark:text-amber-400 flex items-center justify-center font-bold text-sm">
                      {{ u.name.charAt(0).toUpperCase() }}
                    </div>
                    <div>
                      <div class="font-medium text-gray-900 dark:text-white flex items-center gap-2">
                        {{ u.name }}
                      </div>
                      <div class="text-xs text-gray-500 dark:text-gray-400">{{ u.email }}</div>
                      <div v-if="u.phone" class="text-xs text-gray-400 font-mono">{{ u.phone }}</div>
                    </div>
                  </div>
                </td>

                <!-- Rôles Spatie -->
                <td class="py-4 px-6">
                  <div class="flex flex-wrap gap-1.5">
                    <template v-if="u.roles && u.roles.length">
                      <span
                        v-for="r in u.roles"
                        :key="r"
                        class="px-2.5 py-0.5 rounded-full text-xs font-semibold uppercase tracking-wider inline-flex items-center gap-1"
                        :class="roleBadgeColors[r] || 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300'"
                      >
                        {{ r }}
                      </span>
                    </template>
                    <span
                      v-else
                      class="px-2.5 py-0.5 rounded-full text-xs font-semibold uppercase tracking-wider inline-flex items-center gap-1"
                      :class="roleBadgeColors[u.role] || 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300'"
                    >
                      {{ u.role || 'customer' }}
                    </span>
                  </div>
                </td>

                <!-- Statut -->
                <td class="py-4 px-6">
                  <span
                    v-if="u.is_blocked"
                    class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-red-500/10 text-red-600 dark:text-red-400 border border-red-500/20"
                  >
                    <span class="w-1.5 h-1.5 rounded-full bg-red-500"></span>
                    Bloqué
                  </span>
                  <span
                    v-else
                    class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20"
                  >
                    <span class="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                    Actif
                  </span>
                </td>

                <!-- VIP & Points -->
                <td class="py-4 px-6">
                  <div class="text-xs font-semibold text-gray-900 dark:text-white uppercase">
                    {{ u.vip_tier || 'standard' }}
                  </div>
                  <div class="text-xs text-amber-600 dark:text-amber-400 font-medium">
                    {{ u.loyalty_points || 0 }} pts
                  </div>
                </td>

                <!-- Commandes -->
                <td class="py-4 px-6">
                  <span class="text-xs font-medium text-gray-700 dark:text-gray-300">
                    {{ u.orders_count ?? 0 }}
                  </span>
                </td>

                <!-- Date inscription -->
                <td class="py-4 px-6 text-xs text-gray-500 dark:text-gray-400">
                  {{ formatDate(u.created_at) }}
                </td>

                <!-- Actions -->
                <td class="py-4 px-6 text-right">
                  <div class="flex items-center justify-end gap-2">
                    <button
                      @click="toggleBlockUser(u)"
                      class="px-2.5 py-1 rounded-lg text-xs font-medium transition"
                      :class="u.is_blocked ? 'text-emerald-600 bg-emerald-500/10 hover:bg-emerald-500/20' : 'text-red-600 bg-red-500/10 hover:bg-red-500/20'"
                    >
                      {{ u.is_blocked ? 'Débloquer' : 'Bloquer' }}
                    </button>
                    <button
                      @click="editUser(u)"
                      class="px-2.5 py-1 rounded-lg text-xs font-medium text-amber-700 dark:text-amber-400 bg-amber-500/10 hover:bg-amber-500/20 transition"
                    >
                      Éditer
                    </button>
                    <button
                      @click="deleteUser(u)"
                      class="px-2.5 py-1 rounded-lg text-xs font-medium text-red-600 dark:text-red-400 bg-red-500/10 hover:bg-red-500/20 transition"
                    >
                      Suppr.
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Pagination -->
        <div v-if="pagination.lastPage > 1" class="p-4 border-t border-gray-100 dark:border-gray-700 flex items-center justify-between">
          <span class="text-xs text-gray-500 dark:text-gray-400">
            Page {{ pagination.currentPage }} sur {{ pagination.lastPage }} ({{ pagination.total }} utilisateurs)
          </span>
          <div class="flex gap-2">
            <button
              :disabled="pagination.currentPage <= 1"
              @click="load(pagination.currentPage - 1)"
              class="px-3 py-1.5 rounded-lg border border-gray-200 dark:border-gray-700 text-xs font-medium disabled:opacity-50 hover:bg-gray-50 dark:hover:bg-gray-700"
            >
              Précédent
            </button>
            <button
              :disabled="pagination.currentPage >= pagination.lastPage"
              @click="load(pagination.currentPage + 1)"
              class="px-3 py-1.5 rounded-lg border border-gray-200 dark:border-gray-700 text-xs font-medium disabled:opacity-50 hover:bg-gray-50 dark:hover:bg-gray-700"
            >
              Suivant
            </button>
          </div>
        </div>
      </div>

      <!-- Modal Création / Édition Utilisateur -->
      <div
        v-if="showModal"
        class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm"
      >
        <div class="bg-white dark:bg-gray-800 rounded-2xl max-w-xl w-full max-h-[90vh] overflow-y-auto border border-gray-200 dark:border-gray-700 shadow-2xl p-6 space-y-5">
          <div class="flex items-center justify-between border-b border-gray-100 dark:border-gray-700 pb-3">
            <h2 class="text-lg font-bold text-gray-900 dark:text-white">
              {{ form.id ? `Modifier "${form.name}"` : 'Créer un nouvel utilisateur' }}
            </h2>
            <button @click="closeModal" class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-200">
              ✕
            </button>
          </div>

          <div class="space-y-4 text-sm">
            <!-- Nom -->
            <div>
              <label class="block text-xs font-semibold uppercase text-gray-600 dark:text-gray-300 mb-1">Nom complet *</label>
              <input
                v-model="form.name"
                type="text"
                required
                placeholder="ex: Aminata Touré"
                class="w-full px-3.5 py-2 rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-900 text-gray-900 dark:text-white text-sm outline-none"
              />
            </div>

            <!-- Email & Téléphone -->
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <label class="block text-xs font-semibold uppercase text-gray-600 dark:text-gray-300 mb-1">Email *</label>
                <input
                  v-model="form.email"
                  type="email"
                  required
                  placeholder="ex: aminata@example.com"
                  class="w-full px-3.5 py-2 rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-900 text-gray-900 dark:text-white text-sm outline-none"
                />
              </div>
              <div>
                <label class="block text-xs font-semibold uppercase text-gray-600 dark:text-gray-300 mb-1">Téléphone</label>
                <input
                  v-model="form.phone"
                  type="text"
                  placeholder="ex: +225 07 00 00 00"
                  class="w-full px-3.5 py-2 rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-900 text-gray-900 dark:text-white text-sm outline-none"
                />
              </div>
            </div>

            <!-- Mot de passe -->
            <div>
              <label class="block text-xs font-semibold uppercase text-gray-600 dark:text-gray-300 mb-1">
                {{ form.id ? 'Modifier le mot de passe (laisser vide pour ne pas changer)' : 'Mot de passe *' }}
              </label>
              <input
                v-model="form.password"
                type="password"
                :required="!form.id"
                placeholder="••••••••"
                class="w-full px-3.5 py-2 rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-900 text-gray-900 dark:text-white text-sm outline-none"
              />
            </div>

            <!-- Rôles Spatie -->
            <div>
              <label class="block text-xs font-semibold uppercase text-gray-600 dark:text-gray-300 mb-1.5">
                Rôle(s) Attribué(s)
              </label>
              <div class="flex flex-wrap gap-2">
                <button
                  v-for="r in availableRoles"
                  :key="r.id"
                  type="button"
                  @click="toggleFormRole(r.name)"
                  class="px-3 py-1.5 rounded-xl text-xs font-medium border transition flex items-center gap-1.5"
                  :class="form.roles.includes(r.name) ? 'bg-amber-600 text-white border-amber-600 shadow-sm' : 'border-gray-200 dark:border-gray-700 text-gray-700 dark:text-gray-300 bg-gray-50 dark:bg-gray-900 hover:border-amber-500'"
                >
                  <span>{{ form.roles.includes(r.name) ? '✓' : '+' }}</span>
                  <span class="uppercase tracking-wider font-semibold">{{ r.name }}</span>
                </button>
              </div>
              <p class="mt-1 text-xs text-gray-400">
                Tout utilisateur créé sans rôle spécifique est configuré comme <strong>Client</strong> par défaut.
              </p>
            </div>

            <!-- VIP & Fidélité -->
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-2 border-t border-gray-100 dark:border-gray-700">
              <div>
                <label class="block text-xs font-semibold uppercase text-gray-600 dark:text-gray-300 mb-1">Palier VIP</label>
                <select
                  v-model="form.vip_tier"
                  class="w-full px-3.5 py-2 rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-900 text-gray-900 dark:text-white text-sm outline-none"
                >
                  <option value="standard">Standard</option>
                  <option value="gold">Gold</option>
                  <option value="platinum">Platinum</option>
                  <option value="diamond">Diamond</option>
                </select>
              </div>
              <div>
                <label class="block text-xs font-semibold uppercase text-gray-600 dark:text-gray-300 mb-1">Points VIP</label>
                <input
                  v-model="form.loyalty_points"
                  type="number"
                  min="0"
                  class="w-full px-3.5 py-2 rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-900 text-gray-900 dark:text-white text-sm outline-none"
                />
              </div>
            </div>

            <!-- Statut Bloqué -->
            <div class="pt-2">
              <label class="flex items-center gap-2.5 cursor-pointer">
                <input
                  v-model="form.is_blocked"
                  type="checkbox"
                  class="rounded text-red-600 focus:ring-red-500 border-gray-300 dark:border-gray-600"
                />
                <span class="text-xs font-semibold text-gray-700 dark:text-gray-300">
                  Bloquer l'accès à ce compte
                </span>
              </label>
            </div>
          </div>

          <div class="flex items-center justify-end gap-3 border-t border-gray-100 dark:border-gray-700 pt-4">
            <button
              type="button"
              @click="closeModal"
              class="px-4 py-2 rounded-xl border border-gray-200 dark:border-gray-700 text-gray-700 dark:text-gray-300 text-xs font-medium hover:bg-gray-50 dark:hover:bg-gray-700 transition"
            >
              Annuler
            </button>
            <button
              type="button"
              @click="save"
              :disabled="saving"
              class="px-5 py-2 rounded-xl bg-amber-600 hover:bg-amber-700 text-white text-xs font-medium transition disabled:opacity-50 flex items-center gap-2 shadow-sm"
            >
              <svg v-if="saving" class="animate-spin h-3.5 w-3.5" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
              </svg>
              {{ saving ? 'Enregistrement...' : (form.id ? 'Sauvegarder' : 'Créer l’utilisateur') }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>
