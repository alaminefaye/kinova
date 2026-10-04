<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { api, uploadMedia } from '@/api/client'
import ListPager from '@/components/admin/ListPager.vue'
import ActionButton from '@/components/admin/ActionButton.vue'
import StatusBadge from '@/components/admin/StatusBadge.vue'
import TableState from '@/components/admin/TableState.vue'

const uploading = ref(false)

const loading = ref(true)
const saving = ref(false)
const error = ref('')
const products = ref<any[]>([])
const categories = ref<any[]>([])
const form = reactive({
  id: null as number | null,
  category_id: '' as string | number,
  name: '',
  description: '',
  price: 0,
  promo_price: null as number | null,
  stock: 0,
  image_url: '',
  is_active: true,
  is_featured: false,
  is_new: false,
})

const page = ref(1)
const lastPage = ref(1)
const total = ref(0)

async function load(p = page.value) {
  loading.value = true
  error.value = ''
  try {
    const [prodRes, catRes] = await Promise.all([
      api<any>(`/admin/products?page=${p}&per_page=10`),
      api<{ data: any[] }>('/admin/categories'),
    ])
    if (!prodRes.data?.length && p > 1) return await load(p - 1)
    products.value = prodRes.data || []
    page.value = prodRes.current_page || 1
    lastPage.value = prodRes.last_page || 1
    total.value = prodRes.total || 0
    categories.value = catRes.data || []
    if (!form.category_id && categories.value.length) {
      form.category_id = categories.value[0].id
    }
  } catch (e: any) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

function reset() {
  form.id = null
  form.name = ''
  form.description = ''
  form.price = 0
  form.promo_price = null
  form.stock = 0
  form.image_url = ''
  form.is_active = true
  form.is_featured = false
  form.is_new = false
  form.category_id = categories.value[0]?.id || ''
}

function edit(p: any) {
  form.id = p.id
  form.category_id = p.category_id
  form.name = p.name
  form.description = p.description || ''
  form.price = Number(p.price)
  form.promo_price = p.promo_price != null ? Number(p.promo_price) : null
  form.stock = Number(p.stock)
  form.image_url = p.image_url || ''
  form.is_active = !!p.is_active
  form.is_featured = !!p.is_featured
  form.is_new = !!p.is_new
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

async function save() {
  saving.value = true
  error.value = ''
  try {
    const payload = {
      category_id: Number(form.category_id),
      name: form.name,
      description: form.description,
      price: Number(form.price),
      promo_price: form.promo_price && Number(form.promo_price) > 0 ? Number(form.promo_price) : null,
      stock: Number(form.stock),
      image_url: form.image_url || null,
      is_active: form.is_active,
      is_featured: form.is_featured,
      is_new: form.is_new,
    }
    if (form.id) await api(`/admin/products/${form.id}`, { method: 'PUT', json: payload })
    else await api('/admin/products', { method: 'POST', json: payload })
    reset()
    await load()
  } catch (e: any) {
    error.value = e.message
  } finally {
    saving.value = false
  }
}

async function remove(id: number) {
  if (!confirm('Supprimer ce produit ?')) return
  error.value = ''
  try {
    await api(`/admin/products/${id}`, { method: 'DELETE' })
    await load()
  } catch (e: any) {
    error.value = e.message
  }
}

async function onUpload(e: Event) {
  const input = e.target as HTMLInputElement
  const file = input.files?.[0]
  if (!file) return
  uploading.value = true
  error.value = ''
  try {
    const media = await uploadMedia(file)
    form.image_url = media.url
  } catch (err: any) {
    error.value = err.message
  } finally {
    uploading.value = false
    input.value = ''
  }
}

const money = (v: number) =>
  new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'XOF', maximumFractionDigits: 0 }).format(Number(v) || 0)

onMounted(() => load())
</script>

<template>
  <AdminLayout>
    <div class="space-y-6">
      <div>
        <h1 class="text-2xl font-semibold text-gray-800 dark:text-white">Produits</h1>
        <p class="text-sm text-gray-500 mt-1">Catalogue boutique</p>
      </div>

      <div v-if="error" class="rounded-lg border border-error-200 bg-error-50 px-4 py-3 text-error-700">{{ error }}</div>

      <form class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03] grid grid-cols-1 md:grid-cols-2 gap-3" @submit.prevent="save">
        <h2 class="md:col-span-2 font-semibold text-gray-800 dark:text-white">{{ form.id ? 'Modifier produit' : 'Nouveau produit' }}</h2>
        <input v-model="form.name" required placeholder="Nom" class="rounded-lg border border-gray-200 px-3 py-2.5 dark:border-gray-700 dark:bg-gray-900" />
        <select v-model="form.category_id" required class="rounded-lg border border-gray-200 px-3 py-2.5 dark:border-gray-700 dark:bg-gray-900">
          <option v-for="c in categories" :key="c.id" :value="c.id">{{ c.name }}</option>
        </select>
        <input v-model.number="form.price" type="number" step="0.01" min="0" required placeholder="Prix standard" class="rounded-lg border border-gray-200 px-3 py-2.5 dark:border-gray-700 dark:bg-gray-900" />
        <input v-model.number="form.promo_price" type="number" step="0.01" min="0" placeholder="Prix Promo (optionnel)" class="rounded-lg border border-gray-200 px-3 py-2.5 dark:border-gray-700 dark:bg-gray-900" />
        <input v-model.number="form.stock" type="number" min="0" required placeholder="Stock" class="md:col-span-2 rounded-lg border border-gray-200 px-3 py-2.5 dark:border-gray-700 dark:bg-gray-900" />
        <input v-model="form.image_url" type="text" placeholder="URL image ou upload" class="md:col-span-2 rounded-lg border border-gray-200 px-3 py-2.5 dark:border-gray-700 dark:bg-gray-900" />
        <label class="md:col-span-2 text-sm text-gray-500">
          Upload image
          <input type="file" accept="image/*" class="mt-1 block w-full text-sm" :disabled="uploading" @change="onUpload" />
          <span v-if="uploading" class="text-brand-500">Upload…</span>
        </label>
        <img v-if="form.image_url" :src="form.image_url" class="md:col-span-2 h-28 w-28 rounded-lg object-cover" />
        <textarea v-model="form.description" rows="3" placeholder="Description" class="md:col-span-2 rounded-lg border border-gray-200 px-3 py-2.5 dark:border-gray-700 dark:bg-gray-900" />
        <div class="md:col-span-2 flex flex-wrap gap-4 text-sm">
          <label class="flex items-center gap-2"><input v-model="form.is_active" type="checkbox" /> Actif</label>
          <label class="flex items-center gap-2"><input v-model="form.is_featured" type="checkbox" /> Featured</label>
          <label class="flex items-center gap-2"><input v-model="form.is_new" type="checkbox" /> Nouveau</label>
        </div>
        <div class="md:col-span-2 flex gap-2">
          <button type="submit" class="rounded-lg bg-brand-500 px-4 py-2.5 text-sm font-medium text-white" :disabled="saving">{{ saving ? '…' : 'Enregistrer' }}</button>
          <button type="button" class="rounded-lg border border-gray-200 px-4 py-2.5 text-sm" @click="reset">Reset</button>
        </div>
      </form>

      <div class="admin-card">
        <div class="admin-card-header">
          <h2 class="font-semibold text-gray-800 dark:text-white">Liste des produits</h2>
        </div>
        <TableState :loading="loading" :empty="!products.length" empty-text="Aucun produit pour le moment">
          <div class="overflow-x-auto">
            <table class="admin-table min-w-[820px]">
              <thead>
                <tr>
                  <th>Produit</th>
                  <th>Catégorie</th>
                  <th>Prix</th>
                  <th>Stock</th>
                  <th>Statut</th>
                  <th class="text-right">Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="p in products" :key="p.id" :class="{ 'is-selected': form.id === p.id }">
                  <td>
                    <div class="flex items-center gap-3">
                      <img v-if="p.image_url" :src="p.image_url" alt="" class="h-11 w-11 shrink-0 rounded-lg border border-gray-100 object-cover dark:border-gray-800" />
                      <div v-else class="h-11 w-11 shrink-0 rounded-lg bg-gray-100 dark:bg-gray-800" />
                      <div class="min-w-0">
                        <p class="truncate font-medium text-gray-800 dark:text-white">{{ p.name }}</p>
                        <div class="mt-0.5 flex gap-1">
                          <span v-if="p.is_featured" class="rounded bg-brand-50 px-1.5 py-px text-[10px] font-semibold uppercase text-brand-600 dark:bg-white/10 dark:text-brand-300">Vedette</span>
                          <span v-if="p.is_new" class="rounded bg-blue-light-50 px-1.5 py-px text-[10px] font-semibold uppercase text-blue-light-700 dark:bg-blue-light-500/15 dark:text-blue-light-400">Nouveau</span>
                        </div>
                      </div>
                    </div>
                  </td>
                  <td>{{ p.category?.name || '—' }}</td>
                  <td class="whitespace-nowrap">
                    <div v-if="p.promo_price && Number(p.promo_price) > 0">
                      <p class="font-semibold text-error-600 dark:text-error-400">{{ money(p.promo_price) }}</p>
                      <p class="text-xs text-gray-400 line-through">{{ money(p.price) }}</p>
                    </div>
                    <p v-else class="font-medium text-gray-800 dark:text-white">{{ money(p.price) }}</p>
                  </td>
                  <td>
                    <StatusBadge v-if="Number(p.stock) <= 0" label="Épuisé" tone="error" />
                    <StatusBadge v-else-if="Number(p.stock) <= 5" :label="`${p.stock} · faible`" tone="warning" />
                    <span v-else class="font-medium text-gray-800 dark:text-white">{{ p.stock }}</span>
                  </td>
                  <td>
                    <StatusBadge :label="p.is_active ? 'En ligne' : 'Masqué'" :tone="p.is_active ? 'success' : 'gray'" />
                  </td>
                  <td>
                    <div class="flex justify-end gap-1.5">
                      <ActionButton icon="edit" label="Modifier" variant="brand" @click="edit(p)" />
                      <ActionButton icon="trash" label="Supprimer" variant="danger" @click="remove(p.id)" />
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
