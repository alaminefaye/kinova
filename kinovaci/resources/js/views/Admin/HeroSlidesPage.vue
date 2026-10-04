<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { api, uploadMedia } from '@/api/client'
import ListPager from '@/components/admin/ListPager.vue'
import ActionButton from '@/components/admin/ActionButton.vue'
import StatusBadge from '@/components/admin/StatusBadge.vue'
import TableState from '@/components/admin/TableState.vue'
import { useClientPager } from '@/composables/useClientPager'

const loading = ref(true)
const saving = ref(false)
const uploading = ref(false)
const error = ref('')
const slides = ref<any[]>([])
const categories = ref<any[]>([])
const { page, lastPage, pageItems } = useClientPager(slides)

const linkLabel = (slide: any) => {
  if (slide.link_type === 'none') return 'Sans lien'
  if (slide.link_type === 'category') {
    const cat = categories.value.find((c) => String(c.id) === String(slide.link_value))
    return `Catégorie · ${cat?.name ?? '—'}`
  }
  return 'Boutique'
}

const form = reactive({
  id: null as number | null,
  title: '',
  tag: '',
  image_url: '',
  cta_label: 'DÉCOUVRIR',
  link_type: 'catalog',
  link_value: '',
  sort_order: 0,
  is_active: true,
})

async function load() {
  loading.value = true
  error.value = ''
  try {
    const [slidesRes, catsRes] = await Promise.all([
      api<{ data: any[] }>('/admin/hero-slides'),
      api<{ data: any[] }>('/admin/categories'),
    ])
    slides.value = slidesRes.data
    categories.value = catsRes.data
  } catch (e: any) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

function reset() {
  form.id = null
  form.title = ''
  form.tag = ''
  form.image_url = ''
  form.cta_label = 'DÉCOUVRIR'
  form.link_type = 'catalog'
  form.link_value = ''
  form.sort_order = 0
  form.is_active = true
}

function edit(slide: any) {
  form.id = slide.id
  form.title = slide.title || ''
  form.tag = slide.tag || ''
  form.image_url = slide.image_url || ''
  form.cta_label = slide.cta_label || 'DÉCOUVRIR'
  form.link_type = slide.link_type || 'catalog'
  form.link_value = slide.link_value || ''
  form.sort_order = slide.sort_order || 0
  form.is_active = !!slide.is_active
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

async function save() {
  saving.value = true
  error.value = ''
  try {
    const payload = {
      title: form.title,
      tag: form.tag || null,
      image_url: form.image_url,
      cta_label: form.cta_label || 'DÉCOUVRIR',
      link_type: form.link_type || 'catalog',
      link_value: form.link_type === 'category' ? form.link_value || null : null,
      sort_order: Number(form.sort_order) || 0,
      is_active: form.is_active,
    }
    if (form.id) {
      await api(`/admin/hero-slides/${form.id}`, { method: 'PUT', json: payload })
    } else {
      await api('/admin/hero-slides', { method: 'POST', json: payload })
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
  if (!confirm('Supprimer ce slide ?')) return
  error.value = ''
  try {
    await api(`/admin/hero-slides/${id}`, { method: 'DELETE' })
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

onMounted(load)
</script>

<template>
  <AdminLayout>
    <div class="space-y-6">
      <div>
        <h1 class="text-2xl font-semibold text-gray-800 dark:text-white">Slider Accueil</h1>
        <p class="text-sm text-gray-500 mt-1">Gérer les slides du carrousel de l’application mobile</p>
      </div>

      <div v-if="error" class="rounded-lg border border-error-200 bg-error-50 px-4 py-3 text-error-700">{{ error }}</div>

      <div class="grid grid-cols-1 gap-6 xl:grid-cols-3">
        <form
          class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03] space-y-3 xl:col-span-1"
          @submit.prevent="save"
        >
          <h2 class="font-semibold text-gray-800 dark:text-white">
            {{ form.id ? 'Modifier le slide' : 'Nouveau slide' }}
          </h2>

          <textarea
            v-model="form.title"
            rows="2"
            required
            placeholder="Titre (2 lignes possibles)"
            class="w-full rounded-lg border border-gray-200 px-3 py-2.5 dark:border-gray-700 dark:bg-gray-900"
          />
          <input
            v-model="form.tag"
            placeholder="Tag (ex. COLLECTION 2026)"
            class="w-full rounded-lg border border-gray-200 px-3 py-2.5 dark:border-gray-700 dark:bg-gray-900"
          />
          <input
            v-model="form.cta_label"
            placeholder="Libellé bouton"
            class="w-full rounded-lg border border-gray-200 px-3 py-2.5 dark:border-gray-700 dark:bg-gray-900"
          />
          <input
            v-model="form.image_url"
            required
            type="text"
            placeholder="URL image ou upload"
            class="w-full rounded-lg border border-gray-200 px-3 py-2.5 dark:border-gray-700 dark:bg-gray-900"
          />
          <label class="block text-sm text-gray-500">
            Upload image
            <input
              type="file"
              accept="image/*"
              class="mt-1 block w-full text-sm"
              :disabled="uploading"
              @change="onUpload"
            />
            <span v-if="uploading" class="text-brand-500">Upload…</span>
          </label>
          <img
            v-if="form.image_url"
            :src="form.image_url"
            class="h-28 w-full rounded-lg object-cover"
            alt="Aperçu slide"
          />

          <select
            v-model="form.link_type"
            class="w-full rounded-lg border border-gray-200 px-3 py-2.5 dark:border-gray-700 dark:bg-gray-900"
          >
            <option value="catalog">Lien → Boutique</option>
            <option value="category">Lien → Catégorie</option>
            <option value="none">Sans lien</option>
          </select>

          <select
            v-if="form.link_type === 'category'"
            v-model="form.link_value"
            required
            class="w-full rounded-lg border border-gray-200 px-3 py-2.5 dark:border-gray-700 dark:bg-gray-900"
          >
            <option value="" disabled>Choisir une catégorie</option>
            <option v-for="c in categories" :key="c.id" :value="String(c.id)">{{ c.name }}</option>
          </select>

          <input
            v-model.number="form.sort_order"
            type="number"
            min="0"
            placeholder="Ordre"
            class="w-full rounded-lg border border-gray-200 px-3 py-2.5 dark:border-gray-700 dark:bg-gray-900"
          />
          <label class="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-300">
            <input v-model="form.is_active" type="checkbox" /> Actif
          </label>

          <div class="flex gap-2">
            <button
              type="submit"
              class="rounded-lg bg-brand-500 px-4 py-2.5 text-sm font-medium text-white"
              :disabled="saving"
            >
              {{ saving ? '…' : 'Enregistrer' }}
            </button>
            <button type="button" class="rounded-lg border border-gray-200 px-4 py-2.5 text-sm" @click="reset">
              Reset
            </button>
          </div>
        </form>

        <div class="admin-card self-start xl:col-span-2">
          <div class="admin-card-header">
            <h2 class="font-semibold text-gray-800 dark:text-white">Slides du carrousel</h2>
          </div>
          <TableState :loading="loading" :empty="!slides.length" empty-text="Aucun slide pour le moment">
            <div class="overflow-x-auto">
              <table class="admin-table min-w-[640px]">
                <thead>
                  <tr>
                    <th>Slide</th>
                    <th>Lien</th>
                    <th>Ordre</th>
                    <th>Statut</th>
                    <th class="text-right">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="slide in pageItems" :key="slide.id" :class="{ 'is-selected': form.id === slide.id }">
                    <td>
                      <div class="flex items-center gap-3">
                        <img :src="slide.image_url" alt="" class="h-12 w-20 shrink-0 rounded-lg border border-gray-100 object-cover dark:border-gray-800" />
                        <div class="min-w-0">
                          <p class="line-clamp-2 whitespace-pre-line font-medium text-gray-800 dark:text-white">{{ slide.title }}</p>
                          <p class="mt-0.5 text-xs text-gray-500">{{ slide.tag || 'Sans tag' }} · {{ slide.cta_label }}</p>
                        </div>
                      </div>
                    </td>
                    <td class="whitespace-nowrap text-xs">{{ linkLabel(slide) }}</td>
                    <td>{{ slide.sort_order ?? 0 }}</td>
                    <td>
                      <StatusBadge :label="slide.is_active ? 'Actif' : 'Inactif'" :tone="slide.is_active ? 'success' : 'gray'" />
                    </td>
                    <td>
                      <div class="flex justify-end gap-1.5">
                        <ActionButton icon="edit" label="Modifier" variant="brand" @click="edit(slide)" />
                        <ActionButton icon="trash" label="Supprimer" variant="danger" @click="remove(slide.id)" />
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </TableState>
          <ListPager :page="page" :last-page="lastPage" :total="slides.length" @change="page = $event" />
        </div>
      </div>
    </div>
  </AdminLayout>
</template>
