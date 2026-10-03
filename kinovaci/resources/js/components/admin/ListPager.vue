<script setup lang="ts">
defineProps<{ page: number; lastPage: number; total?: number }>()
defineEmits<{ change: [page: number] }>()
</script>

<template>
  <div v-if="lastPage > 1" class="flex items-center justify-between rounded-2xl border border-gray-200 bg-white px-4 py-3 dark:border-gray-800 dark:bg-white/[0.03]">
    <span class="text-sm text-gray-500">
      Page {{ page }} sur {{ lastPage }}<template v-if="total"> · {{ total }} éléments</template>
    </span>
    <div class="flex gap-2">
      <button
        type="button"
        class="rounded-lg border border-gray-200 px-3 py-1.5 text-sm text-gray-700 hover:bg-gray-50 disabled:opacity-40 dark:border-gray-700 dark:text-gray-300 dark:hover:bg-white/5"
        :disabled="page <= 1"
        @click="$emit('change', page - 1)"
      >
        Précédent
      </button>
      <button
        type="button"
        class="rounded-lg border border-gray-200 px-3 py-1.5 text-sm text-gray-700 hover:bg-gray-50 disabled:opacity-40 dark:border-gray-700 dark:text-gray-300 dark:hover:bg-white/5"
        :disabled="page >= lastPage"
        @click="$emit('change', page + 1)"
      >
        Suivant
      </button>
    </div>
  </div>
</template>
