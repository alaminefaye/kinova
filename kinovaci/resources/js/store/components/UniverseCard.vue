<script setup lang="ts">
import SoftImage from './SoftImage.vue'

defineProps<{
  name: string
  imageUrl: string
  count: number
}>()

defineEmits<{ click: [] }>()
</script>

<template>
  <button class="universe" type="button" @click="$emit('click')">
    <SoftImage :url="imageUrl" :alt="name" />
    <div class="veil" />
    <span class="count">{{ count }}</span>
    <div class="meta">
      <span class="bar" />
      <strong>{{ name }}</strong>
      <em>EXPLORER →</em>
    </div>
  </button>
</template>

<style scoped>
.universe {
  position: relative;
  flex: 0 0 148px;
  width: 148px;
  height: 196px;
  border: none;
  padding: 0;
  border-radius: 21px;
  overflow: hidden;
  cursor: pointer;
  box-shadow: 0 7px 14px rgba(62, 39, 35, 0.22);
  background: var(--kv-dark);
}
.veil {
  position: absolute;
  inset: 0;
  background: linear-gradient(
    to bottom,
    transparent 35%,
    rgba(27, 17, 11, 0.25) 60%,
    rgba(27, 17, 11, 0.88) 100%
  );
}
.count {
  position: absolute;
  top: 9px;
  right: 9px;
  padding: 0.25rem 0.55rem;
  border-radius: 999px;
  background: rgba(27, 17, 11, 0.82);
  color: var(--kv-cream);
  font-size: 0.7rem;
  font-weight: 800;
  border: 1px solid rgba(212, 175, 55, 0.75);
}
.meta {
  position: absolute;
  left: 12px;
  right: 12px;
  bottom: 12px;
  text-align: left;
  color: var(--kv-cream);
}
.bar {
  display: block;
  width: 26px;
  height: 2.2px;
  border-radius: 2px;
  background: linear-gradient(90deg, #d4af37, #c5a080);
  margin-bottom: 7px;
}
.meta strong {
  display: block;
  font-family: var(--kv-font-display);
  font-size: 0.98rem;
  font-weight: 700;
}
.meta em {
  font-style: normal;
  color: var(--kv-gold);
  font-size: 0.55rem;
  font-weight: 800;
  letter-spacing: 0.16em;
}
</style>
