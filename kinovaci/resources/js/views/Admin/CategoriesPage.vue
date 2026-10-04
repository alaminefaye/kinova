<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { api } from '@/api/client'
import ListPager from '@/components/admin/ListPager.vue'
import ActionButton from '@/components/admin/ActionButton.vue'
import StatusBadge from '@/components/admin/StatusBadge.vue'
import TableState from '@/components/admin/TableState.vue'
import { useClientPager } from '@/composables/useClientPager'

const loading = ref(true)
const saving = ref(false)
const error = ref('')
const categories = ref<any[]>([])
const { page, lastPage, pageItems } = useClientPager(categories)
const form = reactive({
  id: null as number | null,
  name: '',
  image_url: '',
  sort_order: 0,
  is_active: true,
})

async function load() {
  loading.value = true
  error.value = ''
  try {
    const res = await api<{ data: any[] }>('/admin/categories')
    categories.value = res.data
  } catch (e: any) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

function reset() {
  form.id = null
  form.name = ''
  form.image_url = ''
  form.sort_order = 0
  form.is_active = true
}

function edit(cat: any) {
  form.id = cat.id
  form.name = cat.name
  form.image_url = cat.image_url || ''
  form.sort_order = cat.sort_order || 0
  form.is_active = !!cat.is_active
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

async function save() {
  saving.value = true
  error.value = ''
  try {
    const payload = {
      name: form.name,
      image_url: form.image_url || null,
      sort_order: Number(form.sort_order) || 0,
      is_active: form.is_active,
    }
    if (form.id) {
      await api(`/admin/categories/${form.id}`, { method: 'PUT', json: payload })
    } else {
      await api('/admin/categories', { method: 'POST', json: payload })
    }
    reset()
    await load()
  } catch (e: any) {
    error.value = e.message
  } finally {
    saving.value = false
  }
}

async function remove(id: number) {
  if (!confirm('Supprimer cette catégorie ?')) return
  error.value = ''
  try {
    await api(`/admin/categories/${id}`, { method: 'DELETE' })
    await load()
  } catch (e: any) {
    error.value = e.message
  }
}

onMounted(load)
</script>

<template>
  <AdminLayout>
    <div class="space-y-6">
      <div>
        <h1 class="text-2xl font-semibold text-gray-800 dark:text-white">Catégories</h1>
        <p class="text-sm text-gray-500 mt-1">Gérer les rayons de la boutique</p>
      </div>

      <div v-if="error" class="rounded-lg border border-error-200 bg-error-50 px-4 py-3 text-error-700">{{ error }}</div>

      <div class="grid grid-cols-1 gap-6 xl:grid-cols-3">
        <form class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03] space-y-3 xl:col-span-1" @submit.prevent="save">
          <h2 class="font-semibold text-gray-800 dark:text-white">{{ form.id ? 'Modifier' : 'Nouvelle catégorie' }}</h2>
          <input v-model="form.name" required placeholder="Nom" class="w-full rounded-lg border border-gray-200 px-3 py-2.5 dark:border-gray-700 dark:bg-gray-900" />
          <input v-model="form.image_url" type="url" placeholder="URL image" class="w-full rounded-lg border border-gray-200 px-3 py-2.5 dark:border-gray-700 dark:bg-gray-900" />
          <input v-model.number="form.sort_order" type="number" min="0" placeholder="Ordre" class="w-full rounded-lg border border-gray-200 px-3 py-2.5 dark:border-gray-700 dark:bg-gray-900" />
          <label class="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-300">
            <input v-model="form.is_active" type="checkbox" /> Active
          </label>
          <div class="flex gap-2">
            <button type="submit" class="rounded-lg bg-brand-500 px-4 py-2.5 text-sm font-medium text-white" :disabled="saving">
              {{ saving ? '…' : 'Enregistrer' }}
            </button>
            <button type="button" class="rounded-lg border border-gray-200 px-4 py-2.5 text-sm" @click="reset">Reset</button>
          </div>
        </form>

        <div class="admin-card self-start xl:col-span-2">
          <div class="admin-card-header">
            <h2 class="font-semibold text-gray-800 dark:text-white">Liste des catégories</h2>
          </div>
          <TableState :loading="loading" :empty="!categories.length" empty-text="Aucune catégorie pour le moment">
            <div class="overflow-x-auto">
              <table class="admin-table min-w-[560px]">
                <thead>
                  <tr>
                    <th>Catégorie</th>
                    <th>Produits</th>
                    <th>Ordre</th>
                    <th>Statut</th>
                    <th class="text-right">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="cat in pageItems" :key="cat.id" :class="{ 'is-selected': form.id === cat.id }">
                    <td>
                      <div class="flex items-center gap-3">
                        <img v-if="cat.image_url" :src="cat.image_url" alt="" class="h-10 w-10 shrink-0 rounded-lg border border-gray-100 object-cover dark:border-gray-800" />
                        <div v-else class="h-10 w-10 shrink-0 rounded-lg bg-gray-100 dark:bg-gray-800" />
                        <span class="font-medium text-gray-800 dark:text-white">{{ cat.name }}</span>
                      </div>
                    </td>
                    <td>
                      <span class="font-medium text-gray-800 dark:text-white">{{ cat.products_count ?? 0 }}</span>
                      <span class="text-xs text-gray-400"> article{{ (cat.products_count ?? 0) > 1 ? 's' : '' }}</span>
                    </td>
                    <td>{{ cat.sort_order ?? 0 }}</td>
                    <td>
                      <StatusBadge :label="cat.is_active ? 'Active' : 'Masquée'" :tone="cat.is_active ? 'success' : 'gray'" />
                    </td>
                    <td>
                      <div class="flex justify-end gap-1.5">
                        <ActionButton icon="edit" label="Modifier" variant="brand" @click="edit(cat)" />
                        <ActionButton icon="trash" label="Supprimer" variant="danger" @click="remove(cat.id)" />
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </TableState>
          <ListPager :page="page" :last-page="lastPage" :total="categories.length" @change="page = $event" />
        </div>
      </div>
    </div>
  </AdminLayout>
</template>
