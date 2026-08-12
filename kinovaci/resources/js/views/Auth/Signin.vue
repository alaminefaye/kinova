<template>
  <FullScreenLayout>
    <div class="relative p-6 bg-white z-1 dark:bg-gray-900 sm:p-0">
      <div class="relative flex flex-col justify-center w-full h-screen lg:flex-row dark:bg-gray-900">
        <div class="flex flex-col flex-1 w-full lg:w-1/2">
          <div class="flex flex-col justify-center flex-1 w-full max-w-md mx-auto">
            <div class="mb-5 sm:mb-8">
              <h1 class="mb-2 font-semibold text-gray-800 text-title-sm dark:text-white/90 sm:text-title-md">
                Connexion Admin
              </h1>
              <p class="text-sm text-gray-500 dark:text-gray-400">
                Dashboard KINOVA — email et mot de passe
              </p>
            </div>

            <form class="space-y-5" @submit.prevent="submit">
              <div>
                <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-400">Email</label>
                <input
                  v-model="email"
                  type="email"
                  required
                  class="h-11 w-full rounded-lg border border-gray-300 bg-transparent px-4 py-2.5 text-sm text-gray-800 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90"
                  placeholder="admin@kinova.test"
                />
              </div>
              <div>
                <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-400">Mot de passe</label>
                <input
                  v-model="password"
                  type="password"
                  required
                  class="h-11 w-full rounded-lg border border-gray-300 bg-transparent px-4 py-2.5 text-sm text-gray-800 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90"
                  placeholder="password"
                />
              </div>

              <p v-if="error" class="text-sm text-error-500">{{ error }}</p>

              <button
                type="submit"
                class="flex w-full items-center justify-center rounded-lg bg-brand-500 px-4 py-3 text-sm font-medium text-white hover:bg-brand-600"
                :disabled="loading"
              >
                {{ loading ? 'Connexion…' : 'Se connecter' }}
              </button>
            </form>
          </div>
        </div>

        <div class="relative items-center hidden w-full h-full lg:w-1/2 bg-brand-950 dark:bg-white/5 lg:grid">
          <div class="flex items-center justify-center z-1">
            <div class="flex flex-col items-center max-w-xs">
              <img
                class="mx-auto w-48 h-auto object-contain rounded-lg mb-4"
                src="/images/logo/auth-logo.png"
                alt="KINOVA"
              />
              <p class="text-center text-gray-400 dark:text-white/60">KINOVA — Everything you love</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </FullScreenLayout>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import FullScreenLayout from '@/components/layout/FullScreenLayout.vue'
import { api, setToken } from '@/api/client'

const router = useRouter()
const email = ref('admin@kinova.test')
const password = ref('password')
const loading = ref(false)
const error = ref('')

async function submit() {
  loading.value = true
  error.value = ''
  try {
    const res = await api<{ token: string; user: { role: string } }>('/auth/login', {
      method: 'POST',
      json: { email: email.value, password: password.value },
    })
    if (res.user.role !== 'admin') {
      throw new Error('Compte non admin')
    }
    setToken(res.token)
    router.push('/')
  } catch (e: any) {
    error.value = e.message || 'Connexion impossible'
  } finally {
    loading.value = false
  }
}
</script>
