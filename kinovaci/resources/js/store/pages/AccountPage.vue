<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
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
const loadingOrders = ref(false)
const trackingOrder = ref<OrderSummary | null>(null)

const loggedIn = computed(() => !!getToken())
const user = computed(() => auth.state.user)

const tier = computed(() => {
  if (!loggedIn.value) return 'GUEST'
  const t = String(user.value?.vip_tier || 'standard').toLowerCase()
  if (t === 'vip') return 'VIP'
  if (t === 'gold') return 'OR'
  if (t === 'silver') return 'ARGENT'
  return 'STANDARD'
})

const pointsLabel = computed(() =>
  loggedIn.value ? `${Number(user.value?.loyalty_points || 0)} Points` : '— Points',
)

const subtitle = computed(() => {
  if (!loggedIn.value) return 'Connectez-vous pour vos avantages'
  if (user.value?.email) return user.value.email
  return user.value?.phone || 'Compte KINOVA'
})

async function loadOrders() {
  if (!loggedIn.value) return
  loadingOrders.value = true
  try {
    await auth.refreshProfile()
    const res = await api<any>('/customer/orders')
    orders.value = Array.isArray(res.data) ? res.data : []
  } catch {
    orders.value = []
  } finally {
    loadingOrders.value = false
  }
}

onMounted(() => {
  if (loggedIn.value) loadOrders()
})

function openAuth() {
  router.push({ name: 'auth', query: { redirect: '/compte' } })
}

function openTracking() {
  if (!orders.value.length) {
    alert('Aucune commande à suivre')
    return
  }
  trackingOrder.value = orders.value[0]
}

async function logout() {
  await auth.logout()
  favorites.clear()
  orders.value = []
}

async function deleteAccount() {
  const code = window.prompt('Pour confirmer, tapez : kinovaci')
  if (code !== 'kinovaci') return
  try {
    await api('/customer/profile/delete', {
      method: 'POST',
      json: { confirmation_code: 'kinovaci' },
    })
    await auth.logout()
    favorites.clear()
    orders.value = []
    alert('Compte supprimé')
    router.replace({ name: 'home' })
  } catch (e: any) {
    alert(e?.message || 'Suppression impossible')
  }
}

function formatDate(iso?: string) {
  if (!iso) return ''
  try {
    return new Intl.DateTimeFormat('fr-FR').format(new Date(iso))
  } catch {
    return ''
  }
}
</script>

<template>
  <div class="page kv-container">
    <div class="kv-section-title">
      <h2>Compte Privilège</h2>
    </div>

    <section class="vip-card">
      <div class="row">
        <div class="avatar">
          <img v-if="user?.avatar_url" :src="resolveMediaUrl(user.avatar_url)" alt="" />
          <span v-else>{{ (user?.name || 'K').charAt(0) }}</span>
        </div>
        <div class="meta">
          <div class="name-line">
            <strong>{{ loggedIn ? user?.name : 'Invité KINOVA' }}</strong>
            <span class="tier">{{ tier }}</span>
          </div>
          <p>{{ subtitle }}</p>
        </div>
      </div>

      <div class="divider" />

      <div class="loyalty">
        <div>
          <p class="label">FIDÉLITÉ KINOVA</p>
          <p class="points">{{ pointsLabel }}</p>
        </div>
        <button type="button" class="pill" @click="loggedIn ? loadOrders() : openAuth()">
          {{ loggedIn ? 'Actualiser' : 'Se connecter' }}
        </button>
      </div>
    </section>

    <div class="section-head">
      <h3>Historique de Commandes</h3>
      <span>
        {{
          loadingOrders
            ? '…'
            : `${orders.length} commande${orders.length > 1 ? 's' : ''}`
        }}
      </span>
    </div>

    <div v-if="!loggedIn" class="empty-card">
      <div class="icon">🔒</div>
      <div>
        <strong>Connectez-vous</strong>
        <p>Retrouvez vos commandes et votre suivi livraison.</p>
      </div>
    </div>

    <div v-else-if="loadingOrders && !orders.length" class="loading">Chargement des commandes…</div>

    <div v-else-if="!orders.length" class="empty-card">
      <div class="icon">🛍️</div>
      <div>
        <strong>Aucune commande active</strong>
        <p>Vos futurs achats apparaîtront ici.</p>
      </div>
    </div>

    <article
      v-for="o in orders"
      :key="o.reference"
      class="order-card"
      @click="trackingOrder = o"
    >
      <div class="bag">📦</div>
      <div class="order-body">
        <strong>{{ o.reference }}</strong>
        <p>{{ statusLabel(o.status) }} · {{ formatDate(o.created_at) }}</p>
      </div>
      <span>{{ formatMoney(Number(o.total)) }}</span>
    </article>

    <section class="menu">
      <button v-if="loggedIn" type="button" @click="router.push({ name: 'edit-profile' })">
        <span>👤</span> Modifier mon profil
      </button>
      <button type="button" @click="openTracking">
        <span>🚚</span> Suivi de ma livraison
      </button>
      <button type="button" @click="router.push({ name: 'favorites' })">
        <span>♡</span> Mes pièces enregistrées
      </button>
      <button type="button" @click="router.push({ name: 'help' })">
        <span>?</span> Service Client & Assistance
      </button>
      <button v-if="loggedIn" type="button" class="danger" @click="deleteAccount">
        <span>⌫</span> Supprimer mon compte
      </button>
    </section>

    <button v-if="loggedIn" class="logout" type="button" @click="logout">
      SE DÉCONNECTER
    </button>

    <div v-if="trackingOrder" class="modal" @click.self="trackingOrder = null">
      <div class="modal-card">
        <h4>{{ trackingOrder.reference }}</h4>
        <p>Statut : {{ statusLabel(trackingOrder.status) }}</p>
        <p>Transporteur : {{ trackingOrder.carrier || '—' }}</p>
        <p>Suivi : {{ trackingOrder.tracking_number || '—' }}</p>
        <button class="kv-btn kv-btn-dark" type="button" @click="trackingOrder = null">OK</button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.page {
  padding: 1.1rem 0 2rem;
}
.vip-card {
  padding: 1.35rem;
  border-radius: 22px;
  background: linear-gradient(135deg, #3e2723, #251614);
  border: 1.2px solid rgba(197, 160, 128, 0.35);
  box-shadow: 0 8px 20px rgba(62, 39, 35, 0.35);
  color: var(--kv-cream);
  margin-bottom: 1.6rem;
}
.row {
  display: flex;
  gap: 1rem;
  align-items: center;
}
.avatar {
  width: 52px;
  height: 52px;
  border-radius: 999px;
  overflow: hidden;
  display: grid;
  place-items: center;
  background: rgba(255, 255, 255, 0.08);
  border: 1.5px solid rgba(197, 160, 128, 0.45);
  font-family: var(--kv-font-display);
  font-size: 1.2rem;
  color: var(--kv-gold-light);
  flex-shrink: 0;
}
.avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.meta {
  min-width: 0;
  flex: 1;
}
.name-line {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}
.name-line strong {
  font-size: 1.1rem;
  letter-spacing: 0.03em;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.tier {
  flex-shrink: 0;
  background: var(--kv-gold);
  color: var(--kv-brown);
  font-size: 0.58rem;
  font-weight: 900;
  padding: 0.15rem 0.45rem;
  border-radius: 10px;
}
.meta > p {
  margin: 0.2rem 0 0;
  color: var(--kv-sand);
  font-size: 0.75rem;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.divider {
  height: 1px;
  background: rgba(197, 160, 128, 0.2);
  margin: 1rem 0;
}
.loyalty {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.75rem;
}
.label {
  margin: 0;
  color: var(--kv-gold);
  font-size: 0.6rem;
  font-weight: 700;
  letter-spacing: 0.12em;
}
.points {
  margin: 0.15rem 0 0;
  font-size: 0.95rem;
  font-weight: 700;
}
.pill {
  border: none;
  border-radius: 999px;
  padding: 0.55rem 0.9rem;
  background: rgba(197, 160, 128, 0.2);
  color: var(--kv-cream);
  font-weight: 700;
  font-size: 0.78rem;
  cursor: pointer;
}
.section-head {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  margin-bottom: 0.85rem;
}
.section-head h3 {
  margin: 0;
  font-family: var(--kv-font-display);
  font-size: 1.15rem;
}
.section-head span {
  color: var(--kv-muted);
  font-size: 0.75rem;
}
.empty-card,
.order-card {
  display: flex;
  gap: 0.85rem;
  align-items: center;
  background: var(--kv-surface);
  border-radius: 18px;
  padding: 1.1rem;
  border: 1px solid rgba(197, 160, 128, 0.16);
  box-shadow: var(--kv-shadow);
  margin-bottom: 0.75rem;
  cursor: pointer;
}
.empty-card .icon,
.order-card .bag {
  width: 44px;
  height: 44px;
  border-radius: 999px;
  display: grid;
  place-items: center;
  background: var(--kv-surface-muted);
  flex-shrink: 0;
}
.empty-card strong,
.order-card strong {
  display: block;
  font-size: 0.95rem;
}
.empty-card p,
.order-card p {
  margin: 0.15rem 0 0;
  color: var(--kv-muted);
  font-size: 0.8rem;
}
.order-card span {
  margin-left: auto;
  font-weight: 700;
  font-size: 0.85rem;
}
.loading {
  text-align: center;
  color: var(--kv-muted);
  padding: 1.5rem 0;
}
.menu {
  margin-top: 1.5rem;
  background: var(--kv-surface);
  border-radius: 20px;
  border: 1px solid rgba(197, 160, 128, 0.16);
  box-shadow: var(--kv-shadow);
  overflow: hidden;
}
.menu button {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 0.85rem;
  border: none;
  border-bottom: 1px solid var(--kv-surface-muted);
  background: transparent;
  padding: 1rem 1rem;
  text-align: left;
  color: var(--kv-brown);
  font-weight: 600;
  font-size: 0.9rem;
  cursor: pointer;
}
.menu button:last-child {
  border-bottom: none;
}
.menu button span {
  width: 1.4rem;
  text-align: center;
  color: var(--kv-sand);
}
.menu button.danger {
  color: #8b3a2f;
}
.logout {
  margin-top: 1.1rem;
  width: 100%;
  height: 52px;
  border-radius: 16px;
  border: 1px solid rgba(62, 39, 35, 0.18);
  background: var(--kv-surface);
  color: var(--kv-brown);
  font-weight: 800;
  letter-spacing: 0.12em;
  font-size: 0.78rem;
  cursor: pointer;
  box-shadow: var(--kv-shadow);
}
.modal {
  position: fixed;
  inset: 0;
  background: rgba(27, 17, 11, 0.55);
  display: grid;
  place-items: center;
  z-index: 80;
  padding: 1rem;
}
.modal-card {
  width: min(360px, 100%);
  background: var(--kv-cream);
  border-radius: 18px;
  padding: 1.25rem;
  border: 1px solid rgba(197, 160, 128, 0.3);
}
.modal-card h4 {
  margin: 0 0 0.65rem;
  font-family: var(--kv-font-display);
}
.modal-card p {
  margin: 0.25rem 0;
  color: var(--kv-muted);
  font-size: 0.88rem;
}
.modal-card .kv-btn {
  width: 100%;
  margin-top: 1rem;
}
</style>
