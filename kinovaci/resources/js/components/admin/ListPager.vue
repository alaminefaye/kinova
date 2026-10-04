<script setup lang="ts">
import { computed } from 'vue'
import AdminIcon from './AdminIcon.vue'

const props = withDefaults(defineProps<{ page: number; lastPage: number; total?: number; perPage?: number }>(), {
  total: 0,
  perPage: 10,
})
const emit = defineEmits<{ change: [page: number] }>()

const from = computed(() => (props.total ? (props.page - 1) * props.perPage + 1 : 0))
const to = computed(() => Math.min(props.page * props.perPage, props.total))

/** Numéros affichés : première, dernière et voisines de la page courante, séparées par « … ». */
const pages = computed<(number | '…')[]>(() => {
  const last = props.lastPage
  const wanted = new Set([1, last, props.page - 1, props.page, props.page + 1].filter((p) => p >= 1 && p <= last))
  const sorted = [...wanted].sort((a, b) => a - b)
  const result: (number | '…')[] = []
  sorted.forEach((p, i) => {
    if (i > 0 && p - sorted[i - 1] > 1) result.push('…')
    result.push(p)
  })
  return result
})

function go(p: number) {
  if (p >= 1 && p <= props.lastPage && p !== props.page) emit('change', p)
}

const navButton =
  'inline-flex h-8 min-w-8 items-center justify-center rounded-lg border border-gray-200 px-2 text-sm text-gray-600 transition hover:bg-gray-50 disabled:cursor-not-allowed disabled:opacity-40 dark:border-gray-700 dark:text-gray-300 dark:hover:bg-white/5'
</script>

<template>
  <div
    v-if="total > 0"
    class="flex flex-col gap-3 border-t border-gray-100 px-5 py-3.5 sm:flex-row sm:items-center sm:justify-between dark:border-gray-800"
  >
    <p class="text-sm text-gray-500 dark:text-gray-400">
      <template v-if="lastPage > 1">
        <span class="font-medium text-gray-700 dark:text-gray-200">{{ from }}–{{ to }}</span> sur
      </template>
      <span class="font-medium text-gray-700 dark:text-gray-200">{{ total }}</span>
      {{ total > 1 ? 'éléments' : 'élément' }}
    </p>
    <nav v-if="lastPage > 1" class="flex items-center gap-1" aria-label="Pagination">
      <button type="button" :class="navButton" :disabled="page <= 1" aria-label="Page précédente" @click="go(page - 1)">
        <AdminIcon name="chevron-left" :size="16" />
      </button>
      <template v-for="(p, i) in pages" :key="`${p}-${i}`">
        <span v-if="p === '…'" class="px-1.5 text-sm text-gray-400">…</span>
        <button
          v-else
          type="button"
          :class="[
            'inline-flex h-8 min-w-8 items-center justify-center rounded-lg px-2 text-sm font-medium transition',
            p === page
              ? 'bg-brand-500 text-white shadow-theme-xs dark:bg-brand-300 dark:text-gray-900'
              : 'text-gray-600 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-white/5',
          ]"
          :aria-current="p === page ? 'page' : undefined"
          @click="go(p)"
        >
          {{ p }}
        </button>
      </template>
      <button type="button" :class="navButton" :disabled="page >= lastPage" aria-label="Page suivante" @click="go(page + 1)">
        <AdminIcon name="chevron-right" :size="16" />
      </button>
    </nav>
  </div>
</template>
