<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { api, getToken } from '../api/client'
import { useNotifications } from '../state/notifications'

type Notif = {
  id: number
  title: string
  body?: string
  message?: string
  type?: string
  created_at?: string
  is_read?: boolean | number
}

const router = useRouter()
const notifs = useNotifications()
const items = ref<Notif[]>([])
const error = ref('')
const loading = ref(true)
const filter = ref<'all' | 'unread'>('all')

const visible = computed(() => {
  if (filter.value === 'unread') return items.value.filter((n) => !n.is_read)
  return items.value
})

async function load() {
  if (!getToken()) {
    router.replace({ name: 'auth', query: { redirect: '/notifications' } })
    return
  }
  loading.value = true
  error.value = ''
  try {
    const res = await api<any>('/customer/notifications')
    items.value = Array.isArray(res.data) ? res.data : []
    notifs.setUnread(Number(res.unread_count || 0))
  } catch (e: any) {
    error.value = e?.message || 'Impossible de charger les notifications'
  } finally {
    loading.value = false
  }
}

async function markOne(n: Notif) {
  if (n.is_read) return
  try {
    await api(`/customer/notifications/${n.id}/read`, { method: 'POST' })
    n.is_read = true
    notifs.decrement()
  } catch {
    /* ignore */
  }
}

async function markAll() {
  try {
    await api('/customer/notifications/read-all', { method: 'POST' })
    items.value = items.value.map((n) => ({ ...n, is_read: true }))
    notifs.setUnread(0)
  } catch {
    /* ignore */
  }
}

onMounted(load)
</script>

<template>
  <div class="page">
    <header class="head">
      <div class="kv-container row">
        <button class="round" type="button" @click="router.back()">←</button>
        <h1 class="kv-display">Notifications</h1>
        <button v-if="items.some((n) => !n.is_read)" class="all" type="button" @click="markAll">
          Tout lu
        </button>
      </div>
    </header>

    <div class="kv-container body">
      <div class="filters">
        <button type="button" :class="{ on: filter === 'all' }" @click="filter = 'all'">Toutes</button>
        <button type="button" :class="{ on: filter === 'unread' }" @click="filter = 'unread'">Non lues</button>
      </div>

      <p v-if="loading" class="muted">Chargement…</p>
      <p v-else-if="error" class="error">{{ error }}</p>
      <p v-else-if="!visible.length" class="muted">Aucune notification.</p>

      <article
        v-for="n in visible"
        :key="n.id"
        class="item"
        :class="{ unread: !n.is_read }"
        @click="markOne(n)"
      >
        <h3>{{ n.title }}</h3>
        <p>{{ n.body || n.message }}</p>
      </article>
    </div>
  </div>
</template>

<style scoped>
.page {
  min-height: 100vh;
  background: var(--kv-bg);
}
.head {
  background: linear-gradient(135deg, #3e2723, #251614);
  border-radius: 0 0 28px 28px;
  padding: 1rem 0 1.25rem;
  color: var(--kv-cream);
}
.row {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}
.round {
  width: 42px;
  height: 42px;
  border-radius: 999px;
  border: 1px solid rgba(197, 160, 128, 0.35);
  background: rgba(255, 255, 255, 0.1);
  color: var(--kv-cream);
  cursor: pointer;
}
h1 {
  margin: 0;
  flex: 1;
  font-size: 1.25rem;
  color: #f7e7ce;
}
.all {
  border: none;
  background: rgba(197, 160, 128, 0.2);
  color: var(--kv-gold-light);
  border-radius: 999px;
  padding: 0.45rem 0.75rem;
  font-size: 0.72rem;
  font-weight: 700;
  cursor: pointer;
}
.body {
  padding: 1rem 0 2rem;
}
.filters {
  display: flex;
  gap: 0.45rem;
  margin-bottom: 0.9rem;
}
.filters button {
  border: 1px solid rgba(197, 160, 128, 0.3);
  background: var(--kv-cream);
  border-radius: 999px;
  padding: 0.4rem 0.85rem;
  font-size: 0.75rem;
  font-weight: 700;
  color: var(--kv-muted);
  cursor: pointer;
}
.filters button.on {
  background: var(--kv-brown);
  color: var(--kv-gold-light);
  border-color: transparent;
}
.item {
  background: var(--kv-surface);
  border-radius: 14px;
  padding: 0.9rem 1rem;
  margin-bottom: 0.65rem;
  border: 1px solid rgba(197, 160, 128, 0.18);
  cursor: pointer;
}
.item.unread {
  border-color: rgba(212, 175, 55, 0.55);
  box-shadow: var(--kv-shadow);
}
.item h3 {
  margin: 0 0 0.25rem;
  font-size: 0.92rem;
}
.item p {
  margin: 0;
  color: var(--kv-muted);
  font-size: 0.82rem;
}
.muted {
  color: var(--kv-muted);
}
.error {
  color: #8b3a2f;
}
</style>
