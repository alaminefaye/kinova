<script setup lang="ts">
import AdminIcon from './AdminIcon.vue'

withDefaults(
  defineProps<{
    icon: string
    label: string
    variant?: 'default' | 'brand' | 'danger' | 'success' | 'warning'
    disabled?: boolean
  }>(),
  { variant: 'default', disabled: false },
)
defineEmits<{ click: [event: MouseEvent] }>()

const variants: Record<string, string> = {
  default: 'border-gray-200 bg-white text-gray-600 hover:bg-gray-100 hover:text-gray-900 dark:border-gray-700 dark:bg-transparent dark:text-gray-300 dark:hover:bg-white/5',
  brand: 'border-brand-100 bg-brand-25 text-brand-500 hover:bg-brand-50 dark:border-gray-700 dark:bg-white/5 dark:text-brand-300 dark:hover:bg-white/10',
  danger: 'border-error-100 bg-error-25 text-error-600 hover:bg-error-50 dark:border-error-500/30 dark:bg-transparent dark:text-error-400 dark:hover:bg-error-500/10',
  success: 'border-success-100 bg-success-25 text-success-600 hover:bg-success-50 dark:border-success-500/30 dark:bg-transparent dark:text-success-400 dark:hover:bg-success-500/10',
  warning: 'border-warning-100 bg-warning-25 text-warning-600 hover:bg-warning-50 dark:border-warning-500/30 dark:bg-transparent dark:text-warning-400 dark:hover:bg-warning-500/10',
}
</script>

<template>
  <button
    type="button"
    :aria-label="label"
    :disabled="disabled"
    :class="[
      'group relative inline-flex h-8 w-8 shrink-0 items-center justify-center rounded-lg border transition disabled:cursor-not-allowed disabled:opacity-40',
      variants[variant],
    ]"
    @click="$emit('click', $event)"
  >
    <AdminIcon :name="icon" :size="16" />
    <span
      class="pointer-events-none absolute bottom-full left-1/2 z-30 mb-1.5 -translate-x-1/2 whitespace-nowrap rounded-md bg-gray-900 px-2 py-1 text-[11px] font-medium text-white opacity-0 shadow-lg transition group-hover:opacity-100 dark:bg-gray-700"
    >
      {{ label }}
    </span>
  </button>
</template>
