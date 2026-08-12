<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'

const props = withDefaults(
  defineProps<{
    size?: number
    src?: string
  }>(),
  {
    size: 40,
    src: '/images/logo.png',
  },
)

const progress = ref(0)
let raf = 0
let start = 0

const stroke = computed(() => Math.min(4.5, Math.max(1.5, props.size * 0.045)))
const tipStyle = computed(() => {
  const angle = progress.value * Math.PI * 2 - Math.PI / 2
  const r = props.size / 2 - stroke.value / 2
  const x = props.size / 2 + r * Math.cos(angle)
  const y = props.size / 2 + r * Math.sin(angle)
  return {
    left: `${x}px`,
    top: `${y}px`,
    width: `${stroke.value * 2.2}px`,
    height: `${stroke.value * 2.2}px`,
  }
})

const ringStyle = computed(() => ({
  transform: `rotate(${progress.value * 360}deg)`,
  borderWidth: `${stroke.value}px`,
}))

function tick(now: number) {
  if (!start) start = now
  const elapsed = (now - start) / 4000
  progress.value = elapsed % 1
  raf = requestAnimationFrame(tick)
}

onMounted(() => {
  raf = requestAnimationFrame(tick)
})

onBeforeUnmount(() => {
  cancelAnimationFrame(raf)
})
</script>

<template>
  <div class="badge" :style="{ width: `${size}px`, height: `${size}px` }">
    <div class="track" :style="{ borderWidth: `${stroke * 0.7}px` }" />
    <div class="ring" :style="ringStyle" />
    <div class="tip" :style="tipStyle" />
    <div class="logo">
      <img :src="src" alt="KINOVA" />
    </div>
  </div>
</template>

<style scoped>
.badge {
  position: relative;
  display: inline-grid;
  place-items: center;
  flex-shrink: 0;
}
.track,
.ring {
  position: absolute;
  inset: 0;
  border-radius: 50%;
  border-style: solid;
  pointer-events: none;
}
.track {
  border-color: rgba(193, 168, 149, 0.4);
}
.ring {
  border-color: transparent;
  border-top-color: #c5a080;
  border-right-color: #3e2723;
  border-bottom-color: #d4af37;
  box-sizing: border-box;
}
.tip {
  position: absolute;
  border-radius: 50%;
  background: #fdfbf7;
  box-shadow: 0 0 10px rgba(212, 175, 55, 0.9);
  transform: translate(-50%, -50%);
  pointer-events: none;
}
.logo {
  width: calc(100% - 7px);
  height: calc(100% - 7px);
  border-radius: 50%;
  overflow: hidden;
  background: #f8f2ec;
}
.logo img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}
</style>
