<script setup lang="ts">
import { computed } from 'vue'

const props = withDefaults(defineProps<{ name: string; size?: number }>(), { size: 18 })

const icons: Record<string, string[]> = {
  edit: ['M12 20h9', 'M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4Z'],
  trash: ['M3 6h18', 'M8 6V4h8v2', 'M19 6l-1 14H6L5 6', 'M10 11v6', 'M14 11v6'],
  eye: ['M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12Z', 'M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6Z'],
  lock: ['M5 11h14v10H5z', 'M8 11V7a4 4 0 0 1 8 0v4'],
  unlock: ['M5 11h14v10H5z', 'M8 11V7a4 4 0 0 1 7.8-1.2'],
  plus: ['M12 5v14', 'M5 12h14'],
  minus: ['M5 12h14'],
  check: ['M5 13l4 4L19 7'],
  x: ['M6 6l12 12', 'M18 6 6 18'],
  'chevron-left': ['m15 18-6-6 6-6'],
  'chevron-right': ['m9 18 6-6-6-6'],
  power: ['M12 2v10', 'M18.4 6.6a9 9 0 1 1-12.8 0'],
  phone: [
    'M22 16.9v3a2 2 0 0 1-2.2 2 19.8 19.8 0 0 1-8.6-3.1 19.5 19.5 0 0 1-6-6A19.8 19.8 0 0 1 2.1 4.2 2 2 0 0 1 4.1 2h3a2 2 0 0 1 2 1.7c.1.9.4 1.8.7 2.7a2 2 0 0 1-.5 2.1L8 9.8a16 16 0 0 0 6 6l1.3-1.3a2 2 0 0 1 2.1-.4c.9.3 1.8.6 2.7.7a2 2 0 0 1 1.7 2Z',
  ],
  inbox: [
    'M22 12h-6l-2 3h-4l-2-3H2',
    'M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11Z',
  ],
  search: ['M21 21l-4.3-4.3', 'M11 18a7 7 0 1 0 0-14 7 7 0 0 0 0 14Z'],
  image: ['M3 5h18v14H3z', 'm3 16 5-5 4 4 3-3 6 6', 'M15.5 9.5h.01'],
  send: ['M22 2 11 13', 'M22 2l-7 20-4-9-9-4Z'],
  archive: ['M3 4h18v4H3z', 'M5 8v12h14V8', 'M10 12h4'],
  file: ['M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8Z', 'M14 2v6h6', 'M8 13h8', 'M8 17h5'],
  refresh: ['M21 12a9 9 0 1 1-2.64-6.36', 'M21 4v5h-5'],
  star: ['M12 2l3.1 6.3 6.9 1-5 4.9 1.2 6.8L12 17.8 5.8 21l1.2-6.8-5-4.9 6.9-1Z'],
}

const paths = computed(() => icons[props.name] ?? [])
</script>

<template>
  <svg
    :width="size"
    :height="size"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    stroke-width="2"
    stroke-linecap="round"
    stroke-linejoin="round"
    aria-hidden="true"
  >
    <path v-for="d in paths" :key="d" :d="d" />
  </svg>
</template>
