<script setup lang="ts">
import { onMounted, ref } from 'vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { api, uploadMedia } from '@/api/client'
import ListPager from '@/components/admin/ListPager.vue'
import ActionButton from '@/components/admin/ActionButton.vue'
import StatusBadge from '@/components/admin/StatusBadge.vue'
import TableState from '@/components/admin/TableState.vue'
import { useClientPager } from '@/composables/useClientPager'

interface Announcement {
  id: number
  image_url: string
  is_active: boolean
  views_count: number
  created_at: string
}

const loading = ref(true)
const uploading = ref(false)
const busyId = ref<number | null>(null)
const error = ref('')
const announcements = ref<Announcement[]>([])
const { page, lastPage, pageItems } = useClientPager(announcements)

async function load() {
  loading.value = true
  error.value = ''
  try {
    const res = await api<{ data: Announcement[] }>('/admin/announcements')
    announcements.value = res.data
  } catch (e: any) {
    error.value = e.message
  } finally {
    loading.value = false
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
    await api('/admin/announcements', { method: 'POST', json: { image_url: media.url, is_active: true } })
    await load()
  } catch (err: any) {
    error.value = err.message
  } finally {
    uploading.value = false
    input.value = ''
  }
}

async function toggle(item: Announcement) {
  busyId.value = item.id
  error.value = ''
  try {
    await api(`/admin/announcements/${item.id}`, { method: 'PUT', json: { is_active: !item.is_active } })
    await load()
  } catch (e: any) {
    error.value = e.message
  } finally {
    busyId.value = null
  }
}

async function remove(item: Announcement) {
  if (!confirm('Supprimer cette annonce ?')) return
  busyId.value = item.id
  error.value = ''
  try {
    await api(`/admin/announcements/${item.id}`, { method: 'DELETE' })
    await load()
  } catch (e: any) {
    error.value = e.message
  } finally {
    busyId.value = null
  }
}

function formatDate(value: string) {
  return new Date(value).toLocaleString('fr-FR', { dateStyle: 'medium', timeStyle: 'short' })
}

onMounted(load)
</script>

<template>
  <AdminLayout>
    <div class="space-y-6">
      <div>
        <h1 class="text-2xl font-semibold text-gray-800 dark:text-white">Annonces</h1>
        <p class="text-sm text-gray-500 mt-1">
          Image affichée en popup à l’ouverture de l’application. Une seule annonce est active à la fois ;
          chaque client la voit une fois (1 vue = 1 appareil).
        </p>
      </div>

      <div v-if="error" class="rounded-lg border border-error-200 bg-error-50 px-4 py-3 text-error-700">{{ error }}</div>

      <label
        class="flex cursor-pointer flex-col items-center justify-center gap-2 rounded-2xl border-2 border-dashed border-gray-300 bg-white p-8 text-center hover:border-brand-500 dark:border-gray-700 dark:bg-white/[0.03]"
        :class="{ 'pointer-events-none opacity-60': uploading }"
      >
        <span class="font-medium text-gray-800 dark:text-white">
          {{ uploading ? 'Publication en cours…' : 'Choisir une image à publier' }}
        </span>
        <span class="text-xs text-gray-500">JPG, PNG ou WebP · format portrait ou carré conseillé (ex. 1080 × 1350)</span>
        <input type="file" accept="image/jpeg,image/png,image/webp" class="hidden" :disabled="uploading" @change="onUpload" />
      </label>

      <div class="admin-card">
        <div class="admin-card-header">
          <h2 class="font-semibold text-gray-800 dark:text-white">Annonces publiées</h2>
        </div>
        <TableState :loading="loading" :empty="!announcements.length" empty-text="Aucune annonce pour le moment">
          <div class="grid grid-cols-1 gap-4 p-5 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5">
            <div
              v-for="item in pageItems"
              :key="item.id"
              class="overflow-hidden rounded-xl border bg-white transition dark:bg-white/[0.02]"
              :class="item.is_active ? 'border-success-300 ring-2 ring-success-500/20 dark:border-success-500/50' : 'border-gray-200 dark:border-gray-800'"
            >
              <img :src="item.image_url" class="aspect-[4/5] w-full bg-gray-50 object-contain dark:bg-gray-900" alt="" />
              <div class="space-y-3 p-3">
                <div class="flex items-center justify-between gap-2">
                  <StatusBadge :label="item.is_active ? 'En ligne' : 'Inactive'" :tone="item.is_active ? 'success' : 'gray'" />
                  <span class="text-[11px] text-gray-400">{{ formatDate(item.created_at) }}</span>
                </div>
                <div class="flex items-end justify-between">
                  <p>
                    <span class="text-2xl font-semibold text-gray-800 dark:text-white">{{ (item.views_count ?? 0).toLocaleString('fr-FR') }}</span>
                    <span class="ml-1 text-sm text-gray-500">{{ (item.views_count ?? 0) > 1 ? 'vues' : 'vue' }}</span>
                  </p>
                  <div class="flex gap-1.5">
                    <ActionButton
                      icon="power"
                      :label="item.is_active ? 'Désactiver' : 'Activer'"
                      :variant="item.is_active ? 'warning' : 'success'"
                      :disabled="busyId === item.id"
                      @click="toggle(item)"
                    />
                    <ActionButton icon="trash" label="Supprimer" variant="danger" :disabled="busyId === item.id" @click="remove(item)" />
                  </div>
                </div>
              </div>
            </div>
          </div>
        </TableState>
        <ListPager :page="page" :last-page="lastPage" :total="announcements.length" @change="page = $event" />
      </div>
    </div>
  </AdminLayout>
</template>
