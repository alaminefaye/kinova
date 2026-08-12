import { computed, reactive } from 'vue'
import { api, getToken } from '../api/client'

const state = reactive({
  unread: 0,
})

export function useNotifications() {
  const unread = computed(() => state.unread)

  function setUnread(n: number) {
    state.unread = Math.max(0, n)
  }

  function decrement() {
    state.unread = Math.max(0, state.unread - 1)
  }

  async function refresh() {
    if (!getToken()) {
      state.unread = 0
      return
    }
    try {
      const res = await api<any>('/customer/notifications')
      state.unread = Number(res.unread_count || 0)
    } catch {
      /* ignore */
    }
  }

  return { state, unread, setUnread, decrement, refresh }
}
