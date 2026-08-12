<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { api } from '../api/client'
import { formatMoney, resolveMediaUrl, statusLabel } from '../lib/format'
import { useAuth } from '../state/auth'
import type { OrderSummary } from '../lib/types'

const router = useRouter()
const auth = useAuth()
const orders = ref<OrderSummary[]>([])

onMounted(async () => {
  if (!auth.isLoggedIn.value) {
    router.replace({ name: 'auth', query: { redirect: '/compte' } })
    return
  }
  try {
    const res = await api<any>('/customer/orders')
    orders.value = Array.isArray(res.data) ? res.data : []
  } catch {
    orders.value = []
  }
})

async function logout() {
  await auth.logout()
  router.replace({ name: 'home' })
}
</script>

<template>
  <div class="page kv-container">
    <div class="profile">
      <div class="avatar">
        <img
          v-if="auth.state.user?.avatar_url"
          :src="resolveMediaUrl(auth.state.user.avatar_url)"
          alt=""
        />
        <span v-else>{{ (auth.state.user?.name || 'K').charAt(0) }}</span>
      </div>
      <div>
        <h1 class="kv-display">{{ auth.state.user?.name }}</h1>
        <p>{{ auth.state.user?.phone || auth.state.user?.email }}</p>
      </div>
    </div>

    <section class="card">
      <h2>Mes commandes</h2>
      <div v-if="!orders.length" class="empty">Aucune commande pour le moment.</div>
      <article v-for="o in orders" :key="o.reference" class="order">
        <div>
          <strong>{{ o.reference }}</strong>
          <p>{{ statusLabel(o.status) }}</p>
        </div>
        <span>{{ formatMoney(Number(o.total)) }}</span>
      </article>
    </section>

    <button class="kv-btn kv-btn-ghost full" type="button" @click="logout">Se déconnecter</button>
  </div>
</template>

<style scoped>
.page {
  padding: 1.1rem 0 2rem;
}
.profile {
  display: flex;
  gap: 0.9rem;
  align-items: center;
  margin-bottom: 1.25rem;
}
.avatar {
  width: 64px;
  height: 64px;
  border-radius: 999px;
  overflow: hidden;
  background: linear-gradient(135deg, #3e2723, #251614);
  color: var(--kv-gold-light);
  display: grid;
  place-items: center;
  font-family: var(--kv-font-display);
  font-size: 1.4rem;
  border: 2px solid rgba(197, 160, 128, 0.45);
}
.avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.profile h1 {
  margin: 0;
  font-size: 1.35rem;
}
.profile p {
  margin: 0.2rem 0 0;
  color: var(--kv-muted);
  font-size: 0.85rem;
}
.card {
  background: var(--kv-surface);
  border-radius: 18px;
  padding: 1rem;
  border: 1px solid rgba(197, 160, 128, 0.18);
  margin-bottom: 1rem;
}
.card h2 {
  margin: 0 0 0.75rem;
  font-size: 1rem;
}
.order {
  display: flex;
  justify-content: space-between;
  gap: 0.75rem;
  padding: 0.7rem 0;
  border-top: 1px solid rgba(197, 160, 128, 0.15);
}
.order p {
  margin: 0.15rem 0 0;
  color: var(--kv-muted);
  font-size: 0.78rem;
}
.empty {
  color: var(--kv-muted);
  font-size: 0.88rem;
}
.full {
  width: 100%;
}
</style>
