<template>
  <router-link to="/" class="lg:hidden">
    <img
      class="dark:hidden h-10 w-auto object-contain"
      src="/images/logo/logo.png"
      alt="KINOVA"
    />
    <img
      class="hidden dark:block h-10 w-auto object-contain"
      src="/images/logo/logo-dark.png"
      alt="KINOVA"
    />
  </router-link>
</template>

<script setup>
import { RouterLink } from 'vue-router'
</script>
