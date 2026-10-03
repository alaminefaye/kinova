import { ref } from 'vue'

const TOKEN_KEY = 'kinova_customer_token'

/** Réactif : les `computed` qui lisent getToken() se mettent à jour à la connexion / déconnexion. */
const token = ref<string | null>(localStorage.getItem(TOKEN_KEY))

let unauthorizedHandler: (() => void) | null = null

export function getToken(): string | null {
  return token.value
}

export function setToken(value: string | null) {
  token.value = value || null
  if (!value) localStorage.removeItem(TOKEN_KEY)
  else localStorage.setItem(TOKEN_KEY, value)
}

/** Appelé quand le serveur refuse le jeton (expiré, révoqué, compte bloqué). */
export function onUnauthorized(handler: () => void) {
  unauthorizedHandler = handler
}

type ApiOptions = RequestInit & { json?: unknown }

export async function api<T = any>(path: string, options: ApiOptions = {}): Promise<T> {
  const headers = new Headers(options.headers || {})
  headers.set('Accept', 'application/json')
  headers.set('X-Requested-With', 'XMLHttpRequest')

  if (options.json !== undefined) {
    headers.set('Content-Type', 'application/json')
  }

  const sentToken = getToken()
  if (sentToken) headers.set('Authorization', `Bearer ${sentToken}`)

  const response = await fetch(`/api${path}`, {
    ...options,
    headers,
    body: options.json !== undefined ? JSON.stringify(options.json) : options.body,
  })

  if (response.status === 401 && sentToken) {
    setToken(null)
    unauthorizedHandler?.()
  }

  const data = await response.json().catch(() => ({}))

  if (!response.ok) {
    const message = data.message || data.errors || 'Erreur API'
    throw new Error(typeof message === 'string' ? message : JSON.stringify(message))
  }

  return data as T
}
