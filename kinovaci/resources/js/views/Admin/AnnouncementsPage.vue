<script setup lang="ts">
import { onMounted, ref } from 'vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { api, uploadMedia } from '@/api/client'

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

      <div class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03]">
        <div v-if="loading" class="text-gray-500">Chargement…</div>
        <div v-else-if="announcements.length === 0" class="text-gray-500">Aucune annonce pour le moment.</div>
        <div v-else class="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <div
            v-for="item in announcements"
            :key="item.id"
            class="overflow-hidden rounded-xl border dark:border-gray-800"
            :class="item.is_active ? 'border-green-400' : 'border-gray-100'"
          >
            <img :src="item.image_url" class="aspect-[4/5] w-full bg-gray-50 object-contain dark:bg-gray-900" alt="" />
            <div class="space-y-2 p-3">
              <div class="flex items-center justify-between text-xs">
                <span :class="item.is_active ? 'font-semibold text-green-600' : 'text-gray-400'">
                  {{ item.is_active ? 'Affichée dans l’app' : 'Inactive' }}
                </span>
                <span class="text-gray-400">{{ formatDate(item.created_at) }}</span>
              </div>
              <div class="flex items-baseline gap-1.5">
                <span class="text-2xl font-semibold text-gray-800 dark:text-white">
                  {{ (item.views_count ?? 0).toLocaleString('fr-FR') }}
                </span>
                <span class="text-sm text-gray-500">{{ (item.views_count ?? 0) > 1 ? 'vues' : 'vue' }}</span>
              </div>
              <div class="flex gap-2">
                <button
                  class="flex-1 rounded-lg px-3 py-1.5 text-sm font-medium"
                  :class="
                    item.is_active
                      ? 'border border-gray-200 text-gray-700 dark:border-gray-700 dark:text-gray-300'
                      : 'bg-brand-500 text-white'
                  "
                  :disabled="busyId === item.id"
                  @click="toggle(item)"
                >
                  {{ item.is_active ? 'Désactiver' : 'Activer' }}
                </button>
                <button
                  class="rounded-lg border border-error-200 px-3 py-1.5 text-sm text-error-600"
                  :disabled="busyId === item.id"
                  @click="remove(item)"
                >
                  Suppr.
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>
