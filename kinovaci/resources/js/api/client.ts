const TOKEN_KEY = 'kinova_admin_token'

export function getToken(): string | null {
  return localStorage.getItem(TOKEN_KEY)
}

export function setToken(token: string | null) {
  if (!token) localStorage.removeItem(TOKEN_KEY)
  else localStorage.setItem(TOKEN_KEY, token)
}

type ApiOptions = RequestInit & { json?: unknown }

export async function api<T = any>(path: string, options: ApiOptions = {}): Promise<T> {
  const headers = new Headers(options.headers || {})
  headers.set('Accept', 'application/json')
  headers.set('X-Requested-With', 'XMLHttpRequest')

  if (options.json !== undefined) {
    headers.set('Content-Type', 'application/json')
  }

  const token = getToken()
  if (token) headers.set('Authorization', `Bearer ${token}`)

  const response = await fetch(`/api${path}`, {
    ...options,
    headers,
    body: options.json !== undefined ? JSON.stringify(options.json) : options.body,
  })

  if (response.status === 401) {
    setToken(null)
  }

  const data = await response.json().catch(() => ({}))

  if (!response.ok) {
    const message = data.message || data.errors || 'Erreur API'
    throw new Error(typeof message === 'string' ? message : JSON.stringify(message))
  }

  return data as T
}

export async function uploadMedia(file: File): Promise<{ path: string; url: string }> {
  const form = new FormData()
  form.append('image', file)

  const headers = new Headers()
  headers.set('Accept', 'application/json')
  headers.set('X-Requested-With', 'XMLHttpRequest')
  const token = getToken()
  if (token) headers.set('Authorization', `Bearer ${token}`)

  const response = await fetch('/api/admin/media', {
    method: 'POST',
    headers,
    body: form,
  })

  const data = await response.json().catch(() => ({}))
  if (!response.ok) {
    const message = data.message || data.errors || 'Upload échoué'
    throw new Error(typeof message === 'string' ? message : JSON.stringify(message))
  }

  return data.data
}
