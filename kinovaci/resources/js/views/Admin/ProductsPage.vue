<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { api } from '@/api/client'
import ListPager from '@/components/admin/ListPager.vue'
import ActionButton from '@/components/admin/ActionButton.vue'
import StatusBadge from '@/components/admin/StatusBadge.vue'
import TableState from '@/components/admin/TableState.vue'
import FormField from '@/components/admin/FormField.vue'
import ImageUpload from '@/components/admin/ImageUpload.vue'
import ToggleSwitch from '@/components/admin/ToggleSwitch.vue'

const loading = ref(true)
const saving = ref(false)
const error = ref('')
const success = ref('')
const products = ref<any[]>([])
const categories = ref<any[]>([])
const form = reactive({
  id: null as number | null,
  category_id: '' as string | number,
  name: '',
  description: '',
  price: null as number | null,
  promo_price: null as number | null,
  stock: null as number | null,
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
  form.price = null
  form.promo_price = null
  form.stock = null
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

function flash(message: string) {
  success.value = message
  setTimeout(() => (success.value = ''), 3000)
}

async function save() {
  error.value = ''
  if (form.promo_price && Number(form.promo_price) > 0 && Number(form.promo_price) >= Number(form.price)) {
    error.value = 'Le prix promo doit être inférieur au prix normal.'
    return
  }
  saving.value = true
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
    const editing = !!form.id
    if (editing) await api(`/admin/products/${form.id}`, { method: 'PUT', json: payload })
    else await api('/admin/products', { method: 'POST', json: payload })
    flash(editing ? 'Produit mis à jour.' : 'Produit ajouté au catalogue.')
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

      <div v-if="success" class="rounded-lg border border-success-200 bg-success-50 px-4 py-3 text-sm text-success-700 dark:border-success-500/30 dark:bg-success-500/10 dark:text-success-400">
        {{ success }}
      </div>

      <form class="admin-card" @submit.prevent="save">
        <div class="admin-card-header">
          <div>
            <h2 class="font-semibold text-gray-800 dark:text-white">{{ form.id ? `Modifier « ${form.name} »` : 'Ajouter un produit' }}</h2>
            <p class="text-sm text-gray-500 dark:text-gray-400">Les champs marqués d’une * sont obligatoires.</p>
          </div>
          <button v-if="form.id" type="button" class="admin-btn-secondary" @click="reset">Annuler la modification</button>
        </div>

        <div class="grid grid-cols-1 gap-6 p-5 xl:grid-cols-3">
          <div class="space-y-6 xl:col-span-2">
            <section class="space-y-4">
              <h3 class="admin-section-title">Informations</h3>
              <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
                <FormField label="Nom du produit" for="p-name" required>
                  <input id="p-name" v-model="form.name" required maxlength="255" placeholder="Ex. Crème Velours Karité" class="admin-input" />
                </FormField>
                <FormField label="Catégorie" for="p-category" required hint="Le rayon dans lequel le produit apparaît.">
                  <select id="p-category" v-model="form.category_id" required class="admin-input">
                    <option v-for="c in categories" :key="c.id" :value="c.id">{{ c.name }}</option>
                  </select>
                </FormField>
              </div>
              <FormField label="Description" for="p-description" hint="Matières, utilisation, conseils… affichée sur la fiche produit.">
                <textarea id="p-description" v-model="form.description" rows="4" placeholder="Décrivez le produit pour vos clientes" class="admin-input" />
              </FormField>
            </section>

            <section class="space-y-4">
              <h3 class="admin-section-title">Prix et stock</h3>
              <div class="grid grid-cols-1 gap-4 md:grid-cols-3">
                <FormField label="Prix normal" for="p-price" required>
                  <div class="relative">
                    <input id="p-price" v-model.number="form.price" type="number" min="0" step="1" required placeholder="Ex. 18500" class="admin-input pr-16" />
                    <span class="pointer-events-none absolute inset-y-0 right-3.5 flex items-center text-xs font-medium text-gray-400">FCFA</span>
                  </div>
                </FormField>
                <FormField label="Prix promo" for="p-promo" hint="Laisser vide s’il n’y a pas de promotion.">
                  <div class="relative">
                    <input id="p-promo" v-model.number="form.promo_price" type="number" min="0" step="1" placeholder="Ex. 14900" class="admin-input pr-16" />
                    <span class="pointer-events-none absolute inset-y-0 right-3.5 flex items-center text-xs font-medium text-gray-400">FCFA</span>
                  </div>
                </FormField>
                <FormField label="Stock disponible" for="p-stock" required hint="Nombre d’articles en vente. 0 = épuisé.">
                  <div class="relative">
                    <input id="p-stock" v-model.number="form.stock" type="number" min="0" step="1" required placeholder="Ex. 20" class="admin-input pr-16" />
                    <span class="pointer-events-none absolute inset-y-0 right-3.5 flex items-center text-xs font-medium text-gray-400">pièces</span>
                  </div>
                </FormField>
              </div>
            </section>
          </div>

          <div class="space-y-6">
            <section class="space-y-3">
              <h3 class="admin-section-title">Photo du produit</h3>
              <ImageUpload v-model="form.image_url" hint="carré conseillé, ex. 1000 × 1000" @error="error = $event" />
            </section>

            <section class="space-y-2.5">
              <h3 class="admin-section-title">Visibilité</h3>
              <ToggleSwitch v-model="form.is_active" label="En ligne" description="Visible et commandable dans l’app et sur le site." />
              <ToggleSwitch v-model="form.is_featured" label="Mettre en vedette" description="Affiché dans « Sélection Premium » sur l’accueil." />
              <ToggleSwitch v-model="form.is_new" label="Nouveauté" description="Badge « Nouveau » et section Nouveautés." />
            </section>
          </div>
        </div>

        <div class="flex flex-wrap items-center justify-end gap-3 border-t border-gray-100 px-5 py-4 dark:border-gray-800">
          <button type="button" class="admin-btn-secondary" @click="reset">{{ form.id ? 'Annuler' : 'Vider le formulaire' }}</button>
          <button type="submit" class="admin-btn-primary" :disabled="saving">
            {{ saving ? 'Enregistrement…' : form.id ? 'Enregistrer les modifications' : 'Ajouter le produit' }}
          </button>
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
