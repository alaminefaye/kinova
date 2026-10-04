<script setup lang="ts">
withDefaults(defineProps<{ label: string; hint?: string; required?: boolean; for?: string }>(), {
  hint: '',
  required: false,
  for: undefined,
})
</script>

<template>
  <div class="space-y-1.5">
    <label :for="$props.for" class="block text-sm font-medium text-gray-700 dark:text-gray-300">
      {{ label }}
      <span v-if="required" class="text-error-500">*</span>
    </label>
    <slot />
    <p v-if="hint" class="text-xs leading-relaxed text-gray-500 dark:text-gray-400">{{ hint }}</p>
  </div>
</template>
