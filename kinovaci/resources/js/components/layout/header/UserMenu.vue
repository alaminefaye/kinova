<template>
  <div class="relative" ref="dropdownRef">
    <button
      class="flex items-center text-gray-700 dark:text-gray-400"
      @click.prevent="toggleDropdown"
    >
      <span
        class="mr-3 flex h-11 w-11 items-center justify-center overflow-hidden rounded-full bg-brand-500 font-semibold text-white"
      >
        {{ initial }}
      </span>

      <span class="block mr-1 font-medium text-theme-sm">{{ firstName }}</span>

      <ChevronDownIcon :class="{ 'rotate-180': dropdownOpen }" />
    </button>

    <div
      v-if="dropdownOpen"
      class="absolute right-0 mt-[17px] flex w-[260px] flex-col rounded-2xl border border-gray-200 bg-white p-3 shadow-theme-lg dark:border-gray-800 dark:bg-gray-dark"
    >
      <div>
        <span class="block font-medium text-gray-700 text-theme-sm dark:text-gray-400">
          {{ session.user?.name || 'Administrateur' }}
        </span>
        <span class="mt-0.5 block text-theme-xs text-gray-500 dark:text-gray-400">
          {{ session.user?.email }}
        </span>
        <span
          class="mt-2 inline-block rounded-full bg-brand-50 px-2 py-0.5 text-theme-xs font-medium text-brand-600 dark:bg-brand-500/15 dark:text-brand-400"
        >
          Super-admin
        </span>
      </div>

      <ul class="flex flex-col gap-1 pt-4 pb-3 border-b border-gray-200 dark:border-gray-800">
        <li v-for="item in menuItems" :key="item.href">
          <router-link
            :to="item.href"
            class="flex items-center gap-3 px-3 py-2 font-medium text-gray-700 rounded-lg group text-theme-sm hover:bg-gray-100 hover:text-gray-700 dark:text-gray-400 dark:hover:bg-white/5 dark:hover:text-gray-300"
            @click="closeDropdown"
          >
            <component
              :is="item.icon"
              class="text-gray-500 group-hover:text-gray-700 dark:group-hover:text-gray-300"
            />
            {{ item.text }}
          </router-link>
        </li>
      </ul>
      <button
        type="button"
        :disabled="signingOut"
        class="flex items-center gap-3 px-3 py-2 mt-3 font-medium text-gray-700 rounded-lg group text-theme-sm hover:bg-gray-100 hover:text-gray-700 dark:text-gray-400 dark:hover:bg-white/5 dark:hover:text-gray-300"
        @click="signOut"
      >
        <LogoutIcon class="text-gray-500 group-hover:text-gray-700 dark:group-hover:text-gray-300" />
        {{ signingOut ? 'Déconnexion…' : 'Se déconnecter' }}
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ChevronDownIcon, LogoutIcon, SettingsIcon, UserCircleIcon } from '@/icons'
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { RouterLink, useRouter } from 'vue-router'
import { logout, session } from '@/api/session'

const router = useRouter()
const dropdownOpen = ref(false)
const signingOut = ref(false)
const dropdownRef = ref<HTMLElement | null>(null)

const menuItems = [
  { href: '/settings', icon: SettingsIcon, text: 'Paramètres boutique' },
  { href: '/roles', icon: UserCircleIcon, text: 'Rôles & accès' },
]

const firstName = computed(() => (session.user?.name || 'Admin').split(' ')[0])
const initial = computed(() => (session.user?.name || 'A').charAt(0).toUpperCase())

const toggleDropdown = () => {
  dropdownOpen.value = !dropdownOpen.value
}

const closeDropdown = () => {
  dropdownOpen.value = false
}

async function signOut() {
  signingOut.value = true
  await logout()
  signingOut.value = false
  closeDropdown()
  router.replace({ name: 'Signin' })
}

const handleClickOutside = (event: Event) => {
  if (dropdownRef.value && !dropdownRef.value.contains(event.target as Node)) {
    closeDropdown()
  }
}

onMounted(() => {
  document.addEventListener('click', handleClickOutside)
})

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>
