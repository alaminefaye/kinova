<script setup lang="ts">
import { onMounted } from 'vue'
import StoreLayout from './components/StoreLayout.vue'
import { useAuth } from './state/auth'
import { useCatalog } from './state/catalog'
import { useFavorites } from './state/favorites'
import { useNotifications } from './state/notifications'

const auth = useAuth()
const catalog = useCatalog()
const favorites = useFavorites()
const notifications = useNotifications()

onMounted(async () => {
  await Promise.all([catalog.load(), auth.bootstrap()])
  if (auth.isLoggedIn.value) {
    await favorites.sync()
    await favorites.loadFromApi()
    await notifications.refresh()
  }
})
</script>

<template>
  <StoreLayout>
    <RouterView />
  </StoreLayout>
</template>
