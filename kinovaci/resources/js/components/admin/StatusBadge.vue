<script setup lang="ts">
withDefaults(
  defineProps<{
    label: string
    tone?: 'success' | 'warning' | 'error' | 'info' | 'purple' | 'brand' | 'gray'
    dot?: boolean
  }>(),
  { tone: 'gray', dot: true },
)

const tones: Record<string, { badge: string; dot: string }> = {
  success: { badge: 'bg-success-50 text-success-700 dark:bg-success-500/15 dark:text-success-400', dot: 'bg-success-500' },
  warning: { badge: 'bg-warning-50 text-warning-700 dark:bg-warning-500/15 dark:text-warning-400', dot: 'bg-warning-500' },
  error: { badge: 'bg-error-50 text-error-700 dark:bg-error-500/15 dark:text-error-400', dot: 'bg-error-500' },
  info: { badge: 'bg-blue-light-50 text-blue-light-700 dark:bg-blue-light-500/15 dark:text-blue-light-400', dot: 'bg-blue-light-500' },
  purple: { badge: 'bg-theme-purple-500/10 text-theme-purple-500', dot: 'bg-theme-purple-500' },
  brand: { badge: 'bg-brand-50 text-brand-600 dark:bg-white/10 dark:text-brand-300', dot: 'bg-brand-500 dark:bg-brand-300' },
  gray: { badge: 'bg-gray-100 text-gray-600 dark:bg-white/10 dark:text-gray-300', dot: 'bg-gray-400' },
}
</script>

<template>
  <span :class="['inline-flex items-center gap-1.5 whitespace-nowrap rounded-full px-2.5 py-0.5 text-xs font-medium', tones[tone].badge]">
    <span v-if="dot" :class="['h-1.5 w-1.5 rounded-full', tones[tone].dot]" />
    {{ label }}
  </span>
</template>
