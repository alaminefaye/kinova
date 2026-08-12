<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { api, getToken } from '../api/client'
import { formatMoney, resolveMediaUrl, statusLabel } from '../lib/format'
import { useAuth } from '../state/auth'
import { useFavorites } from '../state/favorites'
import type { OrderSummary } from '../lib/types'

const router = useRouter()
const auth = useAuth()
const favorites = useFavorites()
const orders = ref<OrderSummary[]>([])
const loading = ref(true)
const editing = ref(false)
const saving = ref(false)
const message = ref('')
const error = ref('')

const form = reactive({
  name: '',
  phone: '',
  email: '',
  address: '',
  city: '',
})

const tier = computed(() => {
  const t = String((auth.state.user as any)?.vip_tier || 'standard').toLowerCase()
  if (t === 'vip') return 'VIP'
  if (t === 'gold') return 'OR'
  if (t === 'silver') return 'ARGENT'
  return 'STANDARD'
})

const points = computed(() => Number(auth.state.user?.loyalty_points || 0))

function fillForm() {
  const u = auth.state.user
  form.name = u?.name || ''
  form.phone = u?.phone || ''
  form.email = u?.email || ''
  form.address = u?.address || ''
  form.city = u?.city || ''
}

onMounted(async () => {
  if (!getToken()) {
    router.replace({ name: 'auth', query: { redirect: '/compte' } })
    return
  }
  loading.value = true
  try {
    await auth.refreshProfile()
    fillForm()
    const res = await api<any>('/customer/orders')
    orders.value = Array.isArray(res.data) ? res.data : []
  } catch {
    orders.value = []
  } finally {
    loading.value = false
  }
})

async function saveProfile() {
  saving.value = true
  error.value = ''
  message.value = ''
  try {
    await api('/customer/profile', {
      method: 'PUT',
      json: {
        name: form.name,
        phone: form.phone,
        email: form.email || null,
        address: form.address || null,
        city: form.city || null,
      },
    })
    await auth.refreshProfile()
    fillForm()
    editing.value = false
    message.value = 'Profil mis à jour'
  } catch (e: any) {
    error.value = e?.message || 'Mise à jour impossible'
  } finally {
    saving.value = false
    setTimeout(() => (message.value = ''), 2200)
  }
}

async function logout() {
  await auth.logout()
  await favorites.clear()
  router.replace({ name: 'home' })
}
</script>

<template>
  <div class="page kv-container">
    <div class="kv-section-title">
      <h2>Compte Privilège</h2>
    </div>

    <p v-if="loading" class="muted">Chargement du compte…</p>

    <template v-else>
      <section class="hero">
        <div class="avatar">
          <img
            v-if="auth.state.user?.avatar_url"
            :src="resolveMediaUrl(auth.state.user.avatar_url)"
            alt=""
          />
          <span v-else>{{ (auth.state.user?.name || 'K').charAt(0) }}</span>
        </div>
        <div class="hero-text">
          <h1 class="kv-display">{{ auth.state.user?.name }}</h1>
          <p>{{ auth.state.user?.phone || auth.state.user?.email || '—' }}</p>
          <div class="badges">
            <span>{{ tier }}</span>
            <span>{{ points }} pts</span>
          </div>
        </div>
      </section>

      <section class="card">
        <div class="card-head">
          <h2>Mon profil</h2>
          <button type="button" class="link" @click="editing = !editing">
            {{ editing ? 'Annuler' : 'Modifier' }}
          </button>
        </div>

        <div v-if="!editing" class="info">
          <p><strong>Adresse</strong>{{ auth.state.user?.address || 'Non renseignée' }}</p>
          <p><strong>Ville</strong>{{ auth.state.user?.city || 'Non renseignée' }}</p>
          <p><strong>Email</strong>{{ auth.state.user?.email || 'Non renseigné' }}</p>
        </div>

        <form v-else class="form" @submit.prevent="saveProfile">
          <label>Nom<input v-model="form.name" class="kv-input" required /></label>
          <label>Téléphone<input v-model="form.phone" class="kv-input" required /></label>
          <label>Email<input v-model="form.email" type="email" class="kv-input" /></label>
          <label>Adresse<input v-model="form.address" class="kv-input" /></label>
          <label>Ville<input v-model="form.city" class="kv-input" /></label>
          <p v-if="error" class="error">{{ error }}</p>
          <button class="kv-btn kv-btn-dark" type="submit" :disabled="saving">
            {{ saving ? 'Enregistrement…' : 'Enregistrer' }}
          </button>
        </form>
      </section>

      <section class="card">
        <div class="card-head">
          <h2>Mes commandes</h2>
          <span>{{ orders.length }}</span>
        </div>
        <div v-if="!orders.length" class="empty">Aucune commande pour le moment.</div>
        <article v-for="o in orders" :key="o.reference" class="order">
          <div>
            <strong>{{ o.reference }}</strong>
            <p>{{ statusLabel(o.status) }}</p>
          </div>
          <span>{{ formatMoney(Number(o.total)) }}</span>
        </article>
      </section>

      <section class="links">
        <button type="button" @click="router.push({ name: 'favorites' })">Mes favoris →</button>
        <button type="button" @click="router.push({ name: 'notifications' })">Notifications →</button>
        <button type="button" @click="router.push({ name: 'help' })">Aide & contact →</button>
      </section>

      <button class="kv-btn kv-btn-ghost full" type="button" @click="logout">Se déconnecter</button>
      <p v-if="message" class="toast">{{ message }}</p>
    </template>
  </div>
</template>

<style scoped>
.page {
  padding: 1.1rem 0 2rem;
}
.muted {
  color: var(--kv-muted);
  text-align: center;
  padding: 2rem 0;
}
.hero {
  display: flex;
  gap: 1rem;
  align-items: center;
  padding: 1.2rem;
  border-radius: 22px;
  background: linear-gradient(135deg, #3e2723, #251614);
  color: var(--kv-cream);
  border: 1px solid rgba(197, 160, 128, 0.35);
  box-shadow: 0 10px 24px rgba(62, 39, 35, 0.28);
  margin-bottom: 1rem;
}
.avatar {
  width: 64px;
  height: 64px;
  border-radius: 999px;
  overflow: hidden;
  background: rgba(255, 255, 255, 0.08);
  color: var(--kv-gold-light);
  display: grid;
  place-items: center;
  font-family: var(--kv-font-display);
  font-size: 1.4rem;
  border: 2px solid rgba(197, 160, 128, 0.45);
  flex-shrink: 0;
}
.avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.hero-text h1 {
  margin: 0;
  font-size: 1.35rem;
  color: #f7e7ce;
}
.hero-text p {
  margin: 0.2rem 0 0.55rem;
  color: var(--kv-sand);
  font-size: 0.82rem;
}
.badges {
  display: flex;
  gap: 0.4rem;
  flex-wrap: wrap;
}
.badges span {
  font-size: 0.65rem;
  font-weight: 800;
  letter-spacing: 0.06em;
  padding: 0.28rem 0.55rem;
  border-radius: 999px;
  background: rgba(212, 175, 55, 0.18);
  color: var(--kv-gold-light);
  border: 1px solid rgba(212, 175, 55, 0.4);
}
.card {
  background: var(--kv-surface);
  border-radius: 18px;
  padding: 1rem;
  border: 1px solid rgba(197, 160, 128, 0.18);
  margin-bottom: 1rem;
  box-shadow: var(--kv-shadow);
}
.card-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 0.75rem;
}
.card-head h2 {
  margin: 0;
  font-size: 1rem;
}
.link {
  border: none;
  background: transparent;
  color: var(--kv-gold);
  font-weight: 700;
  cursor: pointer;
  font-size: 0.8rem;
}
.info p {
  display: grid;
  grid-template-columns: 88px 1fr;
  gap: 0.5rem;
  margin: 0 0 0.55rem;
  font-size: 0.86rem;
  color: var(--kv-brown);
}
.info strong {
  color: var(--kv-muted);
  font-weight: 600;
}
.form {
  display: grid;
  gap: 0.7rem;
}
label {
  display: grid;
  gap: 0.3rem;
  font-size: 0.75rem;
  font-weight: 700;
  color: var(--kv-muted);
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
.links {
  display: grid;
  gap: 0.45rem;
  margin-bottom: 1rem;
}
.links button {
  text-align: left;
  border: 1px solid rgba(197, 160, 128, 0.22);
  background: var(--kv-surface);
  border-radius: 14px;
  padding: 0.9rem 1rem;
  color: var(--kv-brown);
  font-weight: 600;
  cursor: pointer;
}
.full {
  width: 100%;
}
.error {
  color: #8b3a2f;
  font-size: 0.85rem;
}
.toast {
  text-align: center;
  color: var(--kv-gold);
  font-weight: 700;
  font-size: 0.85rem;
}
</style>
