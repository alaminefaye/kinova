<script setup lang="ts">
import AdminIcon from './AdminIcon.vue'

withDefaults(defineProps<{ loading: boolean; empty: boolean; emptyText?: string; rows?: number }>(), {
  emptyText: 'Aucun élément pour le moment',
  rows: 5,
})
</script>

<template>
  <div v-if="loading" class="space-y-3 p-5" aria-busy="true">
    <div v-for="i in rows" :key="i" class="flex items-center gap-4">
      <div class="h-10 w-10 shrink-0 animate-pulse rounded-lg bg-gray-100 dark:bg-gray-800" />
      <div class="h-3 flex-1 animate-pulse rounded bg-gray-100 dark:bg-gray-800" />
      <div class="hidden h-3 w-24 animate-pulse rounded bg-gray-100 sm:block dark:bg-gray-800" />
      <div class="h-8 w-20 animate-pulse rounded-lg bg-gray-100 dark:bg-gray-800" />
    </div>
  </div>
  <div v-else-if="empty" class="flex flex-col items-center justify-center gap-3 px-5 py-14 text-center">
    <span class="flex h-12 w-12 items-center justify-center rounded-full bg-gray-100 text-gray-400 dark:bg-gray-800">
      <AdminIcon name="inbox" :size="22" />
    </span>
    <p class="text-sm text-gray-500 dark:text-gray-400">{{ emptyText }}</p>
  </div>
  <slot v-else />
</template>
