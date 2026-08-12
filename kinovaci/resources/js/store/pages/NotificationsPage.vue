<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { api, getToken } from '../api/client'

type Notif = {
  id: number
  title: string
  body?: string
  message?: string
  created_at?: string
  read_at?: string | null
}

const router = useRouter()
const items = ref<Notif[]>([])
const error = ref('')
const loading = ref(true)

async function load() {
  if (!getToken()) {
    router.replace({ name: 'auth', query: { redirect: '/notifications' } })
    return
  }
  loading.value = true
  error.value = ''
  try {
    const res = await api<{ data: Notif[] }>('/customer/notifications')
    items.value = res.data || []
  } catch (e: any) {
    error.value = e?.message || 'Impossible de charger les notifications'
  } finally {
    loading.value = false
  }
}

onMounted(load)
</script>

<template>
  <div class="page kv-container">
    <div class="kv-section-title">
      <h2>Notifications</h2>
    </div>
    <p v-if="loading" class="muted">Chargement…</p>
    <p v-else-if="error" class="error">{{ error }}</p>
    <p v-else-if="!items.length" class="muted">Aucune notification.</p>
    <article v-for="n in items" :key="n.id" class="item" :class="{ unread: !n.read_at }">
      <h3>{{ n.title }}</h3>
      <p>{{ n.body || n.message }}</p>
    </article>
  </div>
</template>

<style scoped>
.page {
  padding: 1.1rem 0 2rem;
}
.item {
  background: var(--kv-surface);
  border-radius: 14px;
  padding: 0.9rem 1rem;
  margin-bottom: 0.65rem;
  border: 1px solid rgba(197, 160, 128, 0.18);
}
.item.unread {
  border-color: rgba(212, 175, 55, 0.55);
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
