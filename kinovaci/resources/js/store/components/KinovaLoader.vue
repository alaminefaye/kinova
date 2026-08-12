<script setup lang="ts">
import AnimatedLogoBadge from './AnimatedLogoBadge.vue'

withDefaults(
  defineProps<{
    size?: number
    message?: string | null
    compact?: boolean
  }>(),
  {
    size: 86,
    message: 'Chargement',
    compact: false,
  },
)
</script>

<template>
  <div class="loader" :class="{ compact }">
    <div class="pulse">
      <AnimatedLogoBadge :size="size" />
    </div>
    <p v-if="message" class="msg">
      <span>{{ message.toUpperCase() }}</span>
      <span class="dots" aria-hidden="true">
        <i /><i /><i />
      </span>
    </p>
  </div>
</template>

<style scoped>
.loader {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 1.1rem;
  padding: 1.5rem;
}
.loader.compact {
  gap: 0.75rem;
  padding: 0.75rem;
}
.pulse {
  animation: kv-pulse 1.4s ease-in-out infinite alternate;
  border-radius: 50%;
}
.loader:not(.compact) .pulse {
  box-shadow: 0 0 28px rgba(212, 175, 55, 0.22);
}
.msg {
  margin: 0;
  display: inline-flex;
  align-items: center;
  gap: 0.15rem;
  font-size: 0.66rem;
  font-weight: 700;
  letter-spacing: 0.2em;
  color: rgba(168, 143, 128, 0.95);
}
.dots {
  display: inline-flex;
  gap: 1px;
  margin-left: 2px;
}
.dots i {
  width: 3px;
  height: 3px;
  border-radius: 50%;
  background: #d4af37;
  opacity: 0.15;
  animation: kv-dot 1.2s infinite;
}
.dots i:nth-child(2) {
  animation-delay: 0.2s;
}
.dots i:nth-child(3) {
  animation-delay: 0.4s;
}
@keyframes kv-pulse {
  from {
    transform: scale(0.96);
    box-shadow: 0 0 18px rgba(212, 175, 55, 0.12);
  }
  to {
    transform: scale(1.02);
    box-shadow: 0 0 36px rgba(212, 175, 55, 0.3);
  }
}
@keyframes kv-dot {
  0%,
  20% {
    opacity: 0.15;
  }
  40%,
  60% {
    opacity: 1;
  }
  80%,
  100% {
    opacity: 0.15;
  }
}
</style>
