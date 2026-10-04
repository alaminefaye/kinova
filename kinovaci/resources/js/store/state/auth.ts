import { computed, reactive } from 'vue'
import { api, getToken, onUnauthorized, setToken } from '../api/client'
import type { UserProfile } from '../lib/types'
import { useCart } from './cart'
import { useFavorites } from './favorites'
import { useNotifications } from './notifications'

const state = reactive({
  user: null as UserProfile | null,
  loading: false,
  bootstrapped: false,
})

/** Efface toutes les données du compte précédent (profil, favoris, badge). */
function resetSession() {
  setToken(null)
  state.user = null
  useFavorites().clear()
  useNotifications().setUnread(0)
}

onUnauthorized(resetSession)

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
    if (getToken()) await logout()
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
    if (getToken()) await logout()
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
    resetSession()
    useCart().clear()
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
