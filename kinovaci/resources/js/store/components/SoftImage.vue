<script setup lang="ts">
import { resolveMediaUrl } from '../lib/format'

defineProps<{
  url: string
  alt?: string
}>()
</script>

<template>
  <img
    class="soft-img"
    :src="resolveMediaUrl(url)"
    :alt="alt || ''"
    loading="lazy"
    @error="($event.target as HTMLImageElement).style.opacity = '0.3'"
  />
</template>

<style scoped>
.soft-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  background: var(--kv-surface-muted);
}
</style>
