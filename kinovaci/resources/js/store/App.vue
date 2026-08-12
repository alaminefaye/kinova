<script setup lang="ts">
import { onMounted } from 'vue'
import StoreLayout from './components/StoreLayout.vue'
import { useAuth } from './state/auth'
import { useCatalog } from './state/catalog'
import { useFavorites } from './state/favorites'

const auth = useAuth()
const catalog = useCatalog()
const favorites = useFavorites()

onMounted(async () => {
  await Promise.all([catalog.load(), auth.bootstrap()])
  if (auth.isLoggedIn.value) {
    await favorites.loadFromApi()
  }
})
</script>

<template>
  <StoreLayout>
    <RouterView />
  </StoreLayout>
</template>
