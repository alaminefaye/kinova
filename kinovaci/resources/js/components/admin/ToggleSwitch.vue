<script setup lang="ts">
withDefaults(defineProps<{ label: string; description?: string }>(), { description: '' })
const model = defineModel<boolean>({ default: false })
</script>

<template>
  <button
    type="button"
    role="switch"
    :aria-checked="model"
    class="flex w-full items-start justify-between gap-4 rounded-xl border border-gray-200 px-4 py-3 text-left transition hover:border-gray-300 dark:border-gray-700 dark:hover:border-gray-600"
    :class="model ? 'bg-brand-25 dark:bg-white/[0.04]' : 'bg-white dark:bg-transparent'"
    @click="model = !model"
  >
    <span class="min-w-0">
      <span class="block text-sm font-medium text-gray-800 dark:text-white">{{ label }}</span>
      <span v-if="description" class="mt-0.5 block text-xs leading-relaxed text-gray-500 dark:text-gray-400">{{ description }}</span>
    </span>
    <span
      class="relative mt-0.5 inline-flex h-6 w-11 shrink-0 items-center rounded-full transition"
      :class="model ? 'bg-brand-500 dark:bg-brand-300' : 'bg-gray-200 dark:bg-gray-700'"
    >
      <span class="inline-block h-5 w-5 rounded-full bg-white shadow-theme-xs transition" :class="model ? 'translate-x-5.5' : 'translate-x-0.5'" />
    </span>
  </button>
</template>
