<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { api } from '@/api/client'
import ListPager from '@/components/admin/ListPager.vue'
import ActionButton from '@/components/admin/ActionButton.vue'
import StatusBadge from '@/components/admin/StatusBadge.vue'
import TableState from '@/components/admin/TableState.vue'
import { useClientPager } from '@/composables/useClientPager'
import FormField from '@/components/admin/FormField.vue'
import ImageUpload from '@/components/admin/ImageUpload.vue'
import ToggleSwitch from '@/components/admin/ToggleSwitch.vue'

const loading = ref(true)
const saving = ref(false)
const error = ref('')
const success = ref('')
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
  error.value = ''
  if (!form.image_url) {
    error.value = 'Ajoutez une image pour le slide.'
    return
  }
  saving.value = true
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
    const editing = !!form.id
    if (editing) {
      await api(`/admin/hero-slides/${form.id}`, { method: 'PUT', json: payload })
    } else {
      await api('/admin/hero-slides', { method: 'POST', json: payload })
    }
    success.value = editing ? 'Slide mis à jour.' : 'Slide ajouté au carrousel.'
    setTimeout(() => (success.value = ''), 3000)
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
      <div v-if="success" class="rounded-lg border border-success-200 bg-success-50 px-4 py-3 text-sm text-success-700 dark:border-success-500/30 dark:bg-success-500/10 dark:text-success-400">
        {{ success }}
      </div>

      <div class="grid grid-cols-1 gap-6 xl:grid-cols-3">
        <form class="admin-card self-start xl:col-span-1" @submit.prevent="save">
          <div class="admin-card-header">
            <div>
              <h2 class="font-semibold text-gray-800 dark:text-white">{{ form.id ? 'Modifier le slide' : 'Nouveau slide' }}</h2>
              <p class="text-sm text-gray-500 dark:text-gray-400">Grande image défilante en haut de l’accueil.</p>
            </div>
          </div>

          <div class="space-y-5 p-5">
            <div>
              <p class="admin-section-title mb-2">Aperçu</p>
              <div class="relative aspect-[16/9] overflow-hidden rounded-xl bg-gray-200 dark:bg-gray-800">
                <img v-if="form.image_url" :src="form.image_url" alt="" class="absolute inset-0 h-full w-full object-cover" />
                <div class="absolute inset-0 bg-gradient-to-t from-black/70 via-black/20 to-transparent" />
                <div class="absolute inset-x-0 bottom-0 space-y-1.5 p-4 text-white">
                  <p v-if="form.tag" class="text-[10px] font-semibold uppercase tracking-[0.2em] text-white/80">{{ form.tag }}</p>
                  <p class="whitespace-pre-line text-lg font-semibold leading-tight">{{ form.title || 'Titre du slide' }}</p>
                  <span v-if="form.link_type !== 'none'" class="inline-block rounded-full bg-white px-3 py-1 text-[10px] font-semibold tracking-wider text-gray-900">
                    {{ form.cta_label || 'DÉCOUVRIR' }}
                  </span>
                </div>
              </div>
            </div>

            <FormField label="Image" required hint="Format paysage conseillé (ex. 1600 × 900).">
              <ImageUpload v-model="form.image_url" shape="wide" hint="paysage" @error="error = $event" />
            </FormField>

            <FormField label="Titre" for="s-title" required hint="Texte principal sur l’image. Retour à la ligne pour 2 lignes.">
              <textarea id="s-title" v-model="form.title" rows="2" required placeholder="Ex. L’élégance&#10;au quotidien" class="admin-input" />
            </FormField>

            <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-1 2xl:grid-cols-2">
              <FormField label="Petit texte au-dessus" for="s-tag" hint="Optionnel, ex. NOUVELLE COLLECTION.">
                <input id="s-tag" v-model="form.tag" maxlength="60" placeholder="Ex. COLLECTION 2026" class="admin-input" />
              </FormField>
              <FormField label="Texte du bouton" for="s-cta">
                <input id="s-cta" v-model="form.cta_label" maxlength="30" placeholder="DÉCOUVRIR" class="admin-input" :disabled="form.link_type === 'none'" />
              </FormField>
            </div>

            <FormField label="Le bouton mène vers" for="s-link">
              <select id="s-link" v-model="form.link_type" class="admin-input">
                <option value="catalog">Toute la boutique</option>
                <option value="category">Une catégorie</option>
                <option value="none">Rien (image seule, sans bouton)</option>
              </select>
            </FormField>
            <FormField v-if="form.link_type === 'category'" label="Catégorie" for="s-category" required>
              <select id="s-category" v-model="form.link_value" required class="admin-input">
                <option value="" disabled>Choisir une catégorie</option>
                <option v-for="c in categories" :key="c.id" :value="String(c.id)">{{ c.name }}</option>
              </select>
            </FormField>

            <FormField label="Ordre d’affichage" for="s-order" hint="Les plus petits numéros passent en premier.">
              <input id="s-order" v-model.number="form.sort_order" type="number" min="0" placeholder="0" class="admin-input" />
            </FormField>
            <ToggleSwitch v-model="form.is_active" label="Slide actif" description="Désactivé, il n’apparaît plus dans le carrousel." />
          </div>

          <div class="flex flex-wrap justify-end gap-3 border-t border-gray-100 px-5 py-4 dark:border-gray-800">
            <button type="button" class="admin-btn-secondary" @click="reset">{{ form.id ? 'Annuler' : 'Vider' }}</button>
            <button type="submit" class="admin-btn-primary" :disabled="saving">
              {{ saving ? 'Enregistrement…' : form.id ? 'Enregistrer' : 'Ajouter le slide' }}
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
