<script setup lang="ts">
import { ref } from 'vue'
import { uploadMedia } from '@/api/client'
import AdminIcon from './AdminIcon.vue'

const props = withDefaults(defineProps<{ shape?: 'square' | 'wide'; hint?: string }>(), {
  shape: 'square',
  hint: 'JPG, PNG ou WebP',
})
const emit = defineEmits<{ error: [message: string] }>()
const model = defineModel<string>({ default: '' })

const uploading = ref(false)
const dragging = ref(false)
const showUrl = ref(false)
const input = ref<HTMLInputElement | null>(null)

async function upload(file?: File | null) {
  if (!file) return
  if (!file.type.startsWith('image/')) {
    emit('error', 'Choisissez un fichier image (JPG, PNG ou WebP).')
    return
  }
  uploading.value = true
  try {
    model.value = (await uploadMedia(file)).url
  } catch (e: any) {
    emit('error', e.message || "L'image n'a pas pu être envoyée.")
  } finally {
    uploading.value = false
    if (input.value) input.value.value = ''
  }
}

function onDrop(e: DragEvent) {
  dragging.value = false
  upload(e.dataTransfer?.files?.[0])
}

const frame = props.shape === 'wide' ? 'aspect-[16/9]' : 'aspect-square max-w-[220px]'
</script>

<template>
  <div class="space-y-2">
    <input ref="input" type="file" accept="image/jpeg,image/png,image/webp" class="hidden" @change="upload(($event.target as HTMLInputElement).files?.[0])" />

    <div v-if="model" :class="['group relative w-full overflow-hidden rounded-xl border border-gray-200 bg-gray-50 dark:border-gray-700 dark:bg-gray-900', frame]">
      <img :src="model" alt="Aperçu" class="h-full w-full object-cover" />
      <div class="absolute inset-x-0 bottom-0 flex gap-2 bg-gradient-to-t from-black/60 to-transparent p-2.5 pt-8">
        <button
          type="button"
          class="flex-1 rounded-lg bg-white/95 px-3 py-1.5 text-xs font-medium text-gray-800 hover:bg-white disabled:opacity-60"
          :disabled="uploading"
          @click="input?.click()"
        >
          {{ uploading ? 'Envoi…' : 'Changer' }}
        </button>
        <button type="button" class="rounded-lg bg-white/95 px-2.5 py-1.5 text-error-600 hover:bg-white" aria-label="Retirer l'image" @click="model = ''">
          <AdminIcon name="trash" :size="14" />
        </button>
      </div>
    </div>

    <button
      v-else
      type="button"
      :class="[
        'flex w-full flex-col items-center justify-center gap-2 rounded-xl border-2 border-dashed px-4 py-7 text-center transition',
        dragging ? 'border-brand-500 bg-brand-25 dark:bg-white/5' : 'border-gray-300 hover:border-brand-300 hover:bg-gray-50 dark:border-gray-700 dark:hover:bg-white/[0.02]',
      ]"
      :disabled="uploading"
      @click="input?.click()"
      @dragover.prevent="dragging = true"
      @dragleave.prevent="dragging = false"
      @drop.prevent="onDrop"
    >
      <span class="flex h-11 w-11 items-center justify-center rounded-full bg-brand-50 text-brand-500 dark:bg-white/10 dark:text-brand-300">
        <svg v-if="uploading" class="h-5 w-5 animate-spin" viewBox="0 0 24 24" fill="none">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
        </svg>
        <AdminIcon v-else name="image" :size="20" />
      </span>
      <span class="text-sm font-medium text-gray-700 dark:text-gray-200">
        {{ uploading ? 'Envoi de l’image…' : 'Cliquez pour choisir une image' }}
      </span>
      <span class="text-xs text-gray-500 dark:text-gray-400">ou glissez-la ici · {{ hint }}</span>
    </button>

    <button type="button" class="text-xs font-medium text-brand-500 hover:underline dark:text-brand-300" @click="showUrl = !showUrl">
      {{ showUrl ? 'Masquer le lien' : 'Ou coller le lien d’une image' }}
    </button>
    <input v-if="showUrl" v-model="model" type="text" placeholder="https://…" class="admin-input" />
  </div>
</template>
