import { reactive } from 'vue'
import { api, getToken, setToken } from './client'

export type AdminUser = {
  id: number
  name: string
  email: string
  roles: string[]
}

export const session = reactive<{ user: AdminUser | null }>({ user: null })

export function isSuperAdmin(user: { roles?: string[] } | null | undefined): boolean {
  return !!user?.roles?.includes('super-admin')
}

/**
 * Vérifie le jeton auprès du serveur. Retourne l'admin connecté, ou null
 * (jeton absent, expiré ou compte non super-admin : la session est alors effacée).
 */
export async function ensureSession(): Promise<AdminUser | null> {
  if (!getToken()) {
    session.user = null
    return null
  }
  if (session.user) return session.user

  try {
    const me = await api<AdminUser>('/auth/me')
    if (!isSuperAdmin(me)) {
      setToken(null)
      return null
    }
    session.user = me
    return me
  } catch {
    return null
  }
}

export async function logout(): Promise<void> {
  try {
    if (getToken()) await api('/auth/logout', { method: 'POST' })
  } catch {
    /* jeton déjà invalide : on efface quand même */
  }
  setToken(null)
  session.user = null
}
