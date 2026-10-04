<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { api } from '@/api/client'
import ListPager from '@/components/admin/ListPager.vue'
import ActionButton from '@/components/admin/ActionButton.vue'
import TableState from '@/components/admin/TableState.vue'
import AdminIcon from '@/components/admin/AdminIcon.vue'
import FormField from '@/components/admin/FormField.vue'
import { useClientPager } from '@/composables/useClientPager'

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
const { page, lastPage, pageItems } = useClientPager(roles)
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
    <div class="space-y-6">
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
      <div class="admin-card">
        <TableState :loading="loading" :empty="!roles.length" empty-text="Aucun rôle pour le moment">
          <div class="overflow-x-auto">
            <table class="admin-table min-w-[760px]">
              <thead>
                <tr>
                  <th>Rôle</th>
                  <th>Membres</th>
                  <th>Permissions accordées</th>
                  <th class="text-right">Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="r in pageItems" :key="r.id">
                  <td>
                    <span
                      class="inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-semibold uppercase tracking-wider"
                      :class="roleBadgeColors[r.name] || 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300'"
                    >
                      <span class="h-1.5 w-1.5 rounded-full bg-current"></span>
                      {{ r.name }}
                    </span>
                  </td>
                  <td>
                    <span class="font-medium text-gray-800 dark:text-white">{{ r.users_count }}</span>
                    <span class="text-xs text-gray-400"> membre{{ r.users_count > 1 ? 's' : '' }}</span>
                  </td>
                  <td class="max-w-md">
                    <p v-if="r.name === 'super-admin'" class="text-xs font-medium text-warning-600 dark:text-warning-400">
                      Accès total : toutes les permissions
                    </p>
                    <div v-else-if="r.permissions && r.permissions.length" class="flex flex-wrap gap-1">
                      <span
                        v-for="p in r.permissions.slice(0, 6)"
                        :key="p"
                        class="rounded-md bg-gray-100 px-2 py-0.5 font-mono text-[11px] text-gray-700 dark:bg-gray-700 dark:text-gray-300"
                      >
                        {{ p }}
                      </span>
                      <span v-if="r.permissions.length > 6" class="rounded-md px-1.5 py-0.5 text-[11px] font-medium text-gray-500">
                        +{{ r.permissions.length - 6 }}
                      </span>
                    </div>
                    <span v-else class="text-xs italic text-gray-400">Aucune permission</span>
                  </td>
                  <td>
                    <div class="flex justify-end gap-1.5">
                      <ActionButton icon="edit" label="Modifier" variant="brand" @click="editRole(r)" />
                      <ActionButton
                        v-if="!['super-admin', 'admin', 'customer'].includes(r.name)"
                        icon="trash"
                        label="Supprimer"
                        variant="danger"
                        @click="deleteRole(r)"
                      />
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </TableState>
        <ListPager :page="page" :last-page="lastPage" :total="roles.length" @change="page = $event" />
      </div>

      <!-- Modal Création / Modification de Rôle -->
      <div
        v-if="showModal"
        class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm"
      >
        <form class="admin-card w-full max-w-2xl max-h-[90vh] overflow-y-auto shadow-2xl" @submit.prevent="saveRole">
          <div class="admin-card-header sticky top-0 z-10 bg-white dark:bg-gray-900">
            <div>
              <h2 class="text-lg font-semibold text-gray-800 dark:text-white">
                {{ modalMode === 'create' ? 'Nouveau rôle' : `Modifier le rôle « ${form.name} »` }}
              </h2>
              <p class="text-xs text-gray-500">Un rôle regroupe ce qu’un membre de l’équipe a le droit de faire.</p>
            </div>
            <button type="button" class="rounded-lg p-1.5 text-gray-400 hover:bg-gray-100 hover:text-gray-600 dark:hover:bg-white/5" aria-label="Fermer" @click="showModal = false">
              <AdminIcon name="x" :size="18" />
            </button>
          </div>

          <div class="space-y-5 p-5">
            <div v-if="error" class="rounded-lg border border-error-200 bg-error-50 px-4 py-3 text-sm text-error-700 dark:border-error-500/30 dark:bg-error-500/10 dark:text-error-400">{{ error }}</div>
            <FormField
              label="Nom du rôle"
              for="r-name"
              required
              :hint="form.name === 'super-admin' ? 'Le rôle super-admin a obligatoirement toutes les permissions.' : 'Un mot simple en minuscules, ex. manager, support, logistique.'"
            >
              <input id="r-name" v-model="form.name" type="text" required :disabled="form.name === 'super-admin'" placeholder="Ex. gestionnaire-stock" class="admin-input" />
            </FormField>

            <!-- Permissions groupées par module -->
            <div v-if="form.name !== 'super-admin'" class="space-y-4 pt-2">
              <div class="flex items-center justify-between">
                <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Ce que ce rôle peut faire</span>
                <div class="flex gap-2 text-xs">
                  <button
                    type="button"
                    @click="selectAllPermissions"
                    class="text-brand-500 dark:text-brand-300 hover:underline font-medium"
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
                    class="text-xs font-medium text-brand-500 dark:text-brand-300 hover:underline"
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
                      class="mt-1 rounded text-brand-500 focus:ring-brand-500 border-gray-300 dark:border-gray-600 dark:bg-gray-700"
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

          <div class="flex flex-wrap justify-end gap-3 border-t border-gray-100 px-5 py-4 dark:border-gray-800">
            <button type="button" class="admin-btn-secondary" @click="showModal = false">Annuler</button>
            <button type="submit" class="admin-btn-primary" :disabled="saving">
              {{ saving ? 'Enregistrement…' : modalMode === 'create' ? 'Créer le rôle' : 'Enregistrer' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </AdminLayout>
</template>
