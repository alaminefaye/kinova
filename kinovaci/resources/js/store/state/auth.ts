import { computed, reactive } from 'vue'
import { api, getToken, setToken } from '../api/client'
import type { UserProfile } from '../lib/types'

const state = reactive({
  user: null as UserProfile | null,
  loading: false,
  bootstrapped: false,
})

export function useAuth() {
  const isLoggedIn = computed(() => !!getToken())

  async function bootstrap() {
    if (!getToken()) {
      state.user = null
      state.bootstrapped = true
      return
    }
    try {
      await refreshProfile()
    } catch {
      setToken(null)
      state.user = null
    } finally {
      state.bootstrapped = true
    }
  }

  async function refreshProfile() {
    const res = await api<{ data: UserProfile }>('/customer/profile')
    state.user = res.data
  }

  async function login(login: string, password: string) {
    state.loading = true
    try {
      const res = await api<{ token: string; user?: UserProfile }>('/customer/auth/login', {
        method: 'POST',
        json: { login, password },
      })
      setToken(res.token)
      if (res.user) state.user = res.user
      else await refreshProfile()
    } finally {
      state.loading = false
    }
  }

  async function register(payload: {
    name: string
    phone: string
    password: string
    email?: string
  }) {
    state.loading = true
    try {
      const res = await api<{ token: string; user?: UserProfile }>('/customer/auth/register', {
        method: 'POST',
        json: {
          ...payload,
          password_confirmation: payload.password,
        },
      })
      setToken(res.token)
      if (res.user) state.user = res.user as UserProfile
      else await refreshProfile()
    } finally {
      state.loading = false
    }
  }

  async function logout() {
    try {
      await api('/auth/logout', { method: 'POST' })
    } catch {
      /* ignore */
    }
    setToken(null)
    state.user = null
  }

  return {
    state,
    isLoggedIn,
    bootstrap,
    refreshProfile,
    login,
    register,
    logout,
  }
}
