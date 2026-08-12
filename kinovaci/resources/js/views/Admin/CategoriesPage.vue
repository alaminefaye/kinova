<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { api } from '@/api/client'

const loading = ref(true)
const saving = ref(false)
const error = ref('')
const categories = ref<any[]>([])
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
  await api(`/admin/categories/${id}`, { method: 'DELETE' })
  await load()
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

        <div class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03] xl:col-span-2">
          <div v-if="loading" class="text-gray-500">Chargement…</div>
          <table v-else class="w-full text-sm">
            <thead>
              <tr class="border-b border-gray-100 text-left text-gray-500 dark:border-gray-800">
                <th class="py-2">Nom</th>
                <th>Produits</th>
                <th>Statut</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="cat in categories" :key="cat.id" class="border-b border-gray-50 dark:border-gray-800">
                <td class="py-3 font-medium text-gray-800 dark:text-white">{{ cat.name }}</td>
                <td>{{ cat.products_count }}</td>
                <td>{{ cat.is_active ? 'Active' : 'Off' }}</td>
                <td class="text-right space-x-2">
                  <button class="text-brand-500" @click="edit(cat)">Éditer</button>
                  <button class="text-error-500" @click="remove(cat.id)">Suppr.</button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>
