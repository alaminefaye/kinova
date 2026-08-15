<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { api } from '@/api/client'

interface PermissionItem {
  id: number
  name: string
  module: string
  label: string
  description: string
}

interface RoleItem {
  id: number
  name: string
  guard_name: string
  users_count: number
  permissions: string[]
  created_at?: string
}

const loading = ref(true)
const saving = ref(false)
const error = ref('')
const successMessage = ref('')

const roles = ref<RoleItem[]>([])
const permissionsGrouped = ref<Record<string, PermissionItem[]>>({})
const allPermissions = ref<PermissionItem[]>([])

const showModal = ref(false)
const modalMode = ref<'create' | 'edit'>('create')

const form = reactive({
  id: null as number | null,
  name: '',
  permissions: [] as string[],
})

const roleBadgeColors: Record<string, string> = {
  'super-admin': 'bg-amber-500/15 text-amber-600 border border-amber-500/30 dark:bg-amber-500/10 dark:text-amber-400',
  'admin': 'bg-blue-500/15 text-blue-600 border border-blue-500/30 dark:bg-blue-500/10 dark:text-blue-400',
  'manager': 'bg-emerald-500/15 text-emerald-600 border border-emerald-500/30 dark:bg-emerald-500/10 dark:text-emerald-400',
  'support': 'bg-purple-500/15 text-purple-600 border border-purple-500/30 dark:bg-purple-500/10 dark:text-purple-400',
  'customer': 'bg-gray-500/15 text-gray-600 border border-gray-500/30 dark:bg-gray-500/10 dark:text-gray-400',
}

async function loadData() {
  loading.value = true
  error.value = ''
  try {
    const [rolesRes, permsRes] = await Promise.all([
      api<RoleItem[]>('/admin/roles'),
      api<{ all: PermissionItem[]; grouped: Record<string, PermissionItem[]> }>('/admin/permissions'),
    ])
    roles.value = rolesRes || []
    permissionsGrouped.value = permsRes.grouped || {}
    allPermissions.value = permsRes.all || []
  } catch (e: any) {
    error.value = e.message || 'Erreur lors du chargement des rôles et permissions.'
  } finally {
    loading.value = false
  }
}

function openCreateModal() {
  modalMode.value = 'create'
  form.id = null
  form.name = ''
  form.permissions = []
  showModal.value = true
}

function editRole(r: RoleItem) {
  modalMode.value = 'edit'
  form.id = r.id
  form.name = r.name
  form.permissions = [...(r.permissions || [])]
  showModal.value = true
}

function togglePermission(permName: string) {
  const index = form.permissions.indexOf(permName)
  if (index >= 0) {
    form.permissions.splice(index, 1)
  } else {
    form.permissions.push(permName)
  }
}

function toggleModulePermissions(module: string) {
  const modulePerms = permissionsGrouped.value[module] || []
  const modulePermNames = modulePerms.map((p) => p.name)
  const hasAll = modulePermNames.every((n) => form.permissions.includes(n))

  if (hasAll) {
    // Retirer toutes les permissions de ce module
    form.permissions = form.permissions.filter((n) => !modulePermNames.includes(n))
  } else {
    // Ajouter toutes les permissions manquantes de ce module
    const toAdd = modulePermNames.filter((n) => !form.permissions.includes(n))
    form.permissions.push(...toAdd)
  }
}

function isModuleFullySelected(module: string): boolean {
  const modulePerms = permissionsGrouped.value[module] || []
  if (!modulePerms.length) return false
  return modulePerms.every((p) => form.permissions.includes(p.name))
}

function selectAllPermissions() {
  form.permissions = allPermissions.value.map((p) => p.name)
}

function deselectAllPermissions() {
  form.permissions = []
}

async function saveRole() {
  if (!form.name.trim()) {
    error.value = 'Le nom du rôle est obligatoire.'
    return
  }

  saving.value = true
  error.value = ''
  try {
    if (modalMode.value === 'create') {
      await api('/admin/roles', {
        method: 'POST',
        json: {
          name: form.name.trim().toLowerCase(),
          permissions: form.permissions,
        },
      })
      successMessage.value = 'Rôle créé avec succès.'
    } else if (form.id) {
      await api(`/admin/roles/${form.id}`, {
        method: 'PUT',
        json: {
          name: form.name.trim().toLowerCase(),
          permissions: form.permissions,
        },
      })
      successMessage.value = 'Rôle mis à jour avec succès.'
    }

    showModal.value = false
    await loadData()
    setTimeout(() => (successMessage.value = ''), 3000)
  } catch (e: any) {
    error.value = e.message || 'Erreur lors de l’enregistrement du rôle.'
  } finally {
    saving.value = false
  }
}

async function deleteRole(r: RoleItem) {
  if (['super-admin', 'admin', 'customer'].includes(r.name)) {
    alert('Les rôles par défaut du système ne peuvent pas être supprimés.')
    return
  }

  if (r.users_count > 0) {
    alert(`Impossible de supprimer ce rôle : il est attribué à ${r.users_count} utilisateur(s).`)
    return
  }

  if (!confirm(`Êtes-vous sûr de vouloir supprimer le rôle "${r.name}" ?`)) {
    return
  }

  loading.value = true
  try {
    await api(`/admin/roles/${r.id}`, { method: 'DELETE' })
    successMessage.value = `Rôle "${r.name}" supprimé.`
    await loadData()
    setTimeout(() => (successMessage.value = ''), 3000)
  } catch (e: any) {
    error.value = e.message || 'Erreur lors de la suppression du rôle.'
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadData()
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
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
              </svg>
            </span>
            Rôles & Permissions
          </h1>
          <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
            Définissez les privilèges d’accès et autorisations des équipes KINOVA (Spatie Laravel Permission).
          </p>
        </div>

        <button
          @click="openCreateModal"
          class="inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-gray-900 dark:bg-white text-white dark:text-gray-900 font-medium hover:bg-gray-800 dark:hover:bg-gray-100 transition shadow-sm"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
          </svg>
          Nouveau Rôle
        </button>
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

      <!-- Tableau des Rôles -->
      <div class="bg-white dark:bg-gray-800 rounded-2xl border border-gray-200 dark:border-gray-700 shadow-sm overflow-hidden">
        <div v-if="loading" class="p-12 text-center text-gray-500 dark:text-gray-400">
          <svg class="animate-spin h-8 w-8 mx-auto text-amber-500" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
          </svg>
          <p class="mt-3 text-sm">Chargement des rôles et autorisations...</p>
        </div>

        <div v-else class="overflow-x-auto">
          <table class="w-full text-left border-collapse">
            <thead>
              <tr class="border-b border-gray-100 dark:border-gray-700/60 bg-gray-50/50 dark:bg-gray-800/50 text-xs uppercase tracking-wider text-gray-500 dark:text-gray-400">
                <th class="py-4 px-6 font-semibold">Rôle</th>
                <th class="py-4 px-6 font-semibold">Utilisateurs</th>
                <th class="py-4 px-6 font-semibold">Permissions accordées</th>
                <th class="py-4 px-6 font-semibold text-right">Actions</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100 dark:divide-gray-700/60 text-sm">
              <tr
                v-for="r in roles"
                :key="r.id"
                class="hover:bg-gray-50/50 dark:hover:bg-gray-700/30 transition-colors"
              >
                <!-- Nom du Rôle -->
                <td class="py-4 px-6">
                  <div class="flex items-center gap-3">
                    <span
                      class="px-3 py-1 rounded-full text-xs font-semibold uppercase tracking-wider inline-flex items-center gap-1.5"
                      :class="roleBadgeColors[r.name] || 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300'"
                    >
                      <span class="w-1.5 h-1.5 rounded-full bg-current"></span>
                      {{ r.name }}
                    </span>
                    <span v-if="r.name === 'super-admin'" class="text-xs text-amber-600 dark:text-amber-400 font-medium">
                      (Accès Total)
                    </span>
                  </div>
                </td>

                <!-- Nombre d'utilisateurs -->
                <td class="py-4 px-6">
                  <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-gray-100 dark:bg-gray-700/60 text-xs font-medium text-gray-700 dark:text-gray-300">
                    <svg class="w-3.5 h-3.5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                    </svg>
                    {{ r.users_count }} membre(s)
                  </span>
                </td>

                <!-- Permissions -->
                <td class="py-4 px-6 max-w-md">
                  <div v-if="r.name === 'super-admin'" class="text-xs font-medium text-amber-600 dark:text-amber-400 flex items-center gap-1.5">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                    </svg>
                    Toutes les permissions système activées
                  </div>
                  <div v-else-if="r.permissions && r.permissions.length" class="flex flex-wrap gap-1.5">
                    <span
                      v-for="p in r.permissions"
                      :key="p"
                      class="px-2 py-0.5 rounded-md bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 text-[11px] font-mono"
                    >
                      {{ p }}
                    </span>
                  </div>
                  <span v-else class="text-xs text-gray-400 italic">Aucune permission</span>
                </td>

                <!-- Actions -->
                <td class="py-4 px-6 text-right">
                  <div class="flex items-center justify-end gap-2">
                    <button
                      @click="editRole(r)"
                      class="px-3 py-1.5 rounded-lg text-xs font-medium text-amber-700 dark:text-amber-400 bg-amber-500/10 hover:bg-amber-500/20 transition"
                    >
                      Modifier
                    </button>
                    <button
                      v-if="!['super-admin', 'admin', 'customer'].includes(r.name)"
                      @click="deleteRole(r)"
                      class="px-3 py-1.5 rounded-lg text-xs font-medium text-red-600 dark:text-red-400 bg-red-500/10 hover:bg-red-500/20 transition"
                    >
                      Supprimer
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Modal Création / Modification de Rôle -->
      <div
        v-if="showModal"
        class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm"
      >
        <div class="bg-white dark:bg-gray-800 rounded-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto border border-gray-200 dark:border-gray-700 shadow-2xl p-6 space-y-6">
          <div class="flex items-center justify-between border-b border-gray-100 dark:border-gray-700 pb-4">
            <h2 class="text-lg font-bold text-gray-900 dark:text-white flex items-center gap-2">
              <svg class="w-5 h-5 text-amber-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4" />
              </svg>
              {{ modalMode === 'create' ? 'Créer un nouveau rôle' : `Modifier le rôle "${form.name}"` }}
            </h2>
            <button
              @click="showModal = false"
              class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-200"
            >
              ✕
            </button>
          </div>

          <div class="space-y-4">
            <!-- Nom du Rôle -->
            <div>
              <label class="block text-xs font-semibold uppercase text-gray-600 dark:text-gray-300 mb-1">
                Identifiant du Rôle (ex: manager, support, logistique)
              </label>
              <input
                v-model="form.name"
                type="text"
                :disabled="form.name === 'super-admin'"
                placeholder="ex: gestionnaire-stock"
                class="w-full px-4 py-2.5 rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-900 text-gray-900 dark:text-white text-sm focus:ring-2 focus:ring-amber-500/20 focus:border-amber-500 outline-none"
              />
              <p v-if="form.name === 'super-admin'" class="mt-1 text-xs text-amber-600 dark:text-amber-400">
                Le rôle super-admin a obligatoirement toutes les permissions.
              </p>
            </div>

            <!-- Permissions groupées par module -->
            <div v-if="form.name !== 'super-admin'" class="space-y-4 pt-2">
              <div class="flex items-center justify-between">
                <span class="text-xs font-semibold uppercase text-gray-600 dark:text-gray-300">
                  Permissions & Autorisations
                </span>
                <div class="flex gap-2 text-xs">
                  <button
                    type="button"
                    @click="selectAllPermissions"
                    class="text-amber-600 dark:text-amber-400 hover:underline font-medium"
                  >
                    Tout cocher
                  </button>
                  <span class="text-gray-300 dark:text-gray-600">|</span>
                  <button
                    type="button"
                    @click="deselectAllPermissions"
                    class="text-gray-500 hover:underline"
                  >
                    Tout décocher
                  </button>
                </div>
              </div>

              <div
                v-for="(modulePerms, moduleName) in permissionsGrouped"
                :key="moduleName"
                class="p-4 rounded-xl border border-gray-100 dark:border-gray-700/60 bg-gray-50/50 dark:bg-gray-900/40 space-y-3"
              >
                <div class="flex items-center justify-between border-b border-gray-200/60 dark:border-gray-700/60 pb-2">
                  <h3 class="text-sm font-semibold text-gray-800 dark:text-gray-200">
                    {{ moduleName }}
                  </h3>
                  <button
                    type="button"
                    @click="toggleModulePermissions(String(moduleName))"
                    class="text-xs font-medium text-amber-600 dark:text-amber-400 hover:underline"
                  >
                    {{ isModuleFullySelected(String(moduleName)) ? 'Désélectionner module' : 'Sélectionner tout le module' }}
                  </button>
                </div>

                <div class="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                  <label
                    v-for="p in modulePerms"
                    :key="p.id"
                    class="flex items-start gap-3 p-2.5 rounded-lg hover:bg-white dark:hover:bg-gray-800 transition cursor-pointer border border-transparent hover:border-gray-200 dark:hover:border-gray-700"
                  >
                    <input
                      type="checkbox"
                      :checked="form.permissions.includes(p.name)"
                      @change="togglePermission(p.name)"
                      class="mt-1 rounded text-amber-600 focus:ring-amber-500 border-gray-300 dark:border-gray-600 dark:bg-gray-700"
                    />
                    <div class="text-xs">
                      <div class="font-medium text-gray-800 dark:text-gray-200">{{ p.label }}</div>
                      <div class="text-gray-500 dark:text-gray-400 text-[11px] leading-tight mt-0.5">
                        {{ p.description }}
                      </div>
                    </div>
                  </label>
                </div>
              </div>
            </div>
          </div>

          <div class="flex items-center justify-end gap-3 border-t border-gray-100 dark:border-gray-700 pt-4">
            <button
              type="button"
              @click="showModal = false"
              class="px-4 py-2.5 rounded-xl border border-gray-200 dark:border-gray-700 text-gray-700 dark:text-gray-300 text-sm font-medium hover:bg-gray-50 dark:hover:bg-gray-700 transition"
            >
              Annuler
            </button>
            <button
              type="button"
              @click="saveRole"
              :disabled="saving"
              class="px-5 py-2.5 rounded-xl bg-amber-600 hover:bg-amber-700 text-white text-sm font-medium transition disabled:opacity-50 flex items-center gap-2 shadow-sm"
            >
              <svg v-if="saving" class="animate-spin h-4 w-4" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
              </svg>
              {{ saving ? 'Enregistrement...' : (modalMode === 'create' ? 'Créer le Rôle' : 'Sauvegarder') }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>
