<script setup lang="ts">
import { onMounted, ref } from 'vue'
import KinovaLoader from './components/KinovaLoader.vue'
import StoreLayout from './components/StoreLayout.vue'
import { useAuth } from './state/auth'
import { useCatalog } from './state/catalog'
import { useFavorites } from './state/favorites'
import { useNotifications } from './state/notifications'

const auth = useAuth()
const catalog = useCatalog()
const favorites = useFavorites()
const notifications = useNotifications()
const booting = ref(true)

onMounted(async () => {
  const started = Date.now()
  await Promise.all([catalog.load(), auth.bootstrap()])
  if (auth.isLoggedIn.value) {
    await favorites.sync()
    await favorites.loadFromApi()
    await notifications.refresh()
  }
  // Laisse l’animation logo/loader se voir un minimum (comme le splash mobile)
  const wait = Math.max(0, 1200 - (Date.now() - started))
  if (wait) await new Promise((r) => setTimeout(r, wait))
  booting.value = false
})
</script>

<template>
  <div v-if="booting" class="boot">
    <KinovaLoader message="Chargement" :size="96" />
  </div>
  <StoreLayout v-else>
    <RouterView />
  </StoreLayout>
</template>

<style scoped>
.boot {
  min-height: 100vh;
  display: grid;
  place-items: center;
  background: radial-gradient(circle at 50% 30%, #2c1e14, #1b110b 55%, #0f0a06 100%);
}
.boot :deep(.msg) {
  color: rgba(232, 215, 200, 0.85);
}
</style>
