<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref } from 'vue'

const props = withDefaults(
  defineProps<{
    phrases: string[]
    typingMs?: number
    deletingMs?: number
    pauseEndMs?: number
    pauseStartMs?: number
  }>(),
  {
    typingMs: 55,
    deletingMs: 28,
    pauseEndMs: 1600,
    pauseStartMs: 400,
  },
)

const text = ref('')
const cursorOn = ref(true)
let phraseIndex = 0
let charIndex = 0
let deleting = false
let typeTimer: ReturnType<typeof setTimeout> | null = null
let cursorTimer: ReturnType<typeof setInterval> | null = null

function schedule(ms: number) {
  if (typeTimer) clearTimeout(typeTimer)
  typeTimer = setTimeout(tick, ms)
}

function tick() {
  if (!props.phrases.length) return
  const phrase = props.phrases[phraseIndex]

  if (!deleting) {
    if (charIndex < phrase.length) {
      charIndex++
      text.value = phrase.slice(0, charIndex)
      schedule(props.typingMs)
    } else {
      deleting = true
      schedule(props.pauseEndMs)
    }
    return
  }

  if (charIndex > 0) {
    charIndex--
    text.value = phrase.slice(0, charIndex)
    schedule(props.deletingMs)
    return
  }

  deleting = false
  phraseIndex = (phraseIndex + 1) % props.phrases.length
  schedule(props.pauseStartMs)
}

onMounted(() => {
  schedule(props.pauseStartMs)
  cursorTimer = setInterval(() => {
    cursorOn.value = !cursorOn.value
  }, 480)
})

onBeforeUnmount(() => {
  if (typeTimer) clearTimeout(typeTimer)
  if (cursorTimer) clearInterval(cursorTimer)
})
</script>

<template>
  <span class="hint">{{ text }}<span class="cursor" :class="{ on: cursorOn }">|</span></span>
</template>

<style scoped>
.hint {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.cursor {
  opacity: 0;
  margin-left: 1px;
}
.cursor.on {
  opacity: 0.75;
}
</style>
