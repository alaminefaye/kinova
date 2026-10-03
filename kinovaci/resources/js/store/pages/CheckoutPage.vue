<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { getToken } from '../api/client'
import { formatMoney } from '../lib/format'
import { useAuth } from '../state/auth'
import { useCart } from '../state/cart'
import { useSettings } from '../state/settings'

const router = useRouter()
const auth = useAuth()
const cart = useCart()
const error = ref('')
const loading = ref(false)

const settings = useSettings()
const form = reactive({
  customer_name: '',
  customer_phone: '',
  customer_email: '',
  is_delivery: false,
  address: '',
  city: '',
  delivery_details: '',
  notes: '',
})
const position = ref<{ latitude: number; longitude: number; accuracy: number } | null>(null)
const locating = ref(false)
const locationError = ref('')
const consentOpen = ref(false)

function askLocation() {
  if (!locating.value) consentOpen.value = true
}

function locate() {
  consentOpen.value = false
  locationError.value = ''
  if (!('geolocation' in navigator)) {
    locationError.value = 'La géolocalisation n’est pas disponible sur cet appareil.'
    return
  }
  locating.value = true
  navigator.geolocation.getCurrentPosition(
    (p) => {
      position.value = {
        latitude: p.coords.latitude,
        longitude: p.coords.longitude,
        accuracy: Math.round(p.coords.accuracy),
      }
      locating.value = false
    },
    () => {
      locationError.value = 'Position refusée ou introuvable. Autorisez la localisation et réessayez.'
      locating.value = false
    },
    { enableHighAccuracy: true, timeout: 20000 },
  )
}

onMounted(async () => {
  if (!getToken()) {
    router.replace({ name: 'auth', query: { redirect: '/commande' } })
    return
  }
  if (!auth.state.user) {
    try {
      await auth.refreshProfile()
    } catch {
      router.replace({ name: 'auth', query: { redirect: '/commande' } })
      return
    }
  }
  const u = auth.state.user
  form.customer_name = u?.name || ''
  form.customer_phone = u?.phone || ''
  form.customer_email = u?.email || ''
  form.address = u?.address || ''
  form.city = u?.city || ''
})

async function submit() {
  if (loading.value) return
  if (!getToken()) {
    router.replace({ name: 'auth', query: { redirect: '/commande' } })
    return
  }
  if (!cart.state.items.length) {
    router.push({ name: 'cart' })
    return
  }
  if (form.is_delivery && !position.value && !form.address.trim()) {
    error.value = 'Indiquez une adresse ou partagez votre position.'
    return
  }
  error.value = ''
  loading.value = true
  try {
    const order = await cart.placeOrder({
      customer_name: form.customer_name,
      customer_phone: form.customer_phone,
      customer_email: form.customer_email || undefined,
      is_delivery: form.is_delivery,
      address: form.is_delivery ? form.address : 'Retrait en boutique KINOVA',
      city: form.is_delivery ? form.city || 'Abidjan' : 'Abidjan',
      latitude: form.is_delivery ? position.value?.latitude ?? null : null,
      longitude: form.is_delivery ? position.value?.longitude ?? null : null,
      delivery_details: form.is_delivery ? form.delivery_details || undefined : undefined,
      notes: form.notes || undefined,
    })
    router.replace({
      name: 'order-success',
      params: { reference: order.reference || order.id },
      query: { total: String(order.total ?? '') },
    })
  } catch (e: any) {
    error.value = e?.message || 'Commande impossible'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="page kv-container">
    <div class="kv-section-title">
      <h2>Commande</h2>
    </div>

    <form class="form" @submit.prevent="submit">
      <label>Nom complet<input v-model="form.customer_name" class="kv-input" required /></label>
      <label>Téléphone<input v-model="form.customer_phone" class="kv-input" required /></label>
      <label>Email (optionnel)<input v-model="form.customer_email" type="email" class="kv-input" /></label>
      <label class="toggle">
        <input v-model="form.is_delivery" type="checkbox" />
        <span>
          <strong>Se faire livrer à domicile</strong>
          <small>{{ form.is_delivery ? 'Frais à régler directement au livreur' : 'Option : sinon retrait en boutique KINOVA (gratuit)' }}</small>
        </span>
      </label>

      <template v-if="form.is_delivery">
        <div class="geo">
          <div>
            <strong>{{ position ? 'Position exacte enregistrée' : 'Ma position exacte' }}</strong>
            <small v-if="position">Précision ±{{ position.accuracy }} m</small>
            <small v-else>Partagez votre position pour que le livreur vous trouve.</small>
            <small v-if="locationError" class="error">{{ locationError }}</small>
          </div>
          <button type="button" class="kv-btn" :disabled="locating" @click="askLocation">
            {{ locating ? 'Localisation…' : position ? 'Actualiser' : 'Utiliser ma position' }}
          </button>
        </div>
        <label>
          Quartier / adresse {{ position ? '(facultatif)' : '*' }}
          <input v-model="form.address" class="kv-input" />
        </label>
        <label>Ville<input v-model="form.city" class="kv-input" placeholder="Abidjan" /></label>
        <label>
          Précisions pour le livreur
          <textarea
            v-model="form.delivery_details"
            class="kv-input"
            rows="3"
            maxlength="1000"
            placeholder="Repères, immeuble, étage, couleur du portail…"
          />
        </label>
        <p v-if="settings.state.data.shipping.note" class="note">{{ settings.state.data.shipping.note }}</p>
      </template>

      <div class="pay">
        <strong>Paiement à la livraison / au retrait</strong>
        <small>Espèces ou mobile money, à la réception du colis</small>
      </div>
      <label>Notes<textarea v-model="form.notes" class="kv-input" rows="3" /></label>

      <div v-if="cart.state.items.length" class="order-items-recap">
        <div
          v-for="item in cart.state.items"
          :key="item.product.id + (item.selectedSize || '') + (item.selectedColor || '')"
          class="recap-row"
        >
          <div class="recap-info">
            <span class="recap-name">{{ item.product.name }} × {{ item.quantity }}</span>
            <span v-if="item.selectedSize || item.selectedColor" class="recap-variants">
              <span v-if="item.selectedSize">Taille : {{ item.selectedSize }}</span>
              <span v-if="item.selectedSize && item.selectedColor"> · </span>
              <span v-if="item.selectedColor">Couleur : {{ item.selectedColor }}</span>
            </span>
          </div>
          <span class="recap-price">
            {{ formatMoney((item.product.promoPrice && item.product.promoPrice < item.product.price ? item.product.promoPrice : item.product.price) * item.quantity) }}
          </span>
        </div>
      </div>

      <div class="sum">
        {{ form.is_delivery && cart.shippingToCourier.value ? 'Total (hors livraison)' : 'Total à payer' }} :
        <strong>{{ formatMoney(cart.subtotal.value + (form.is_delivery ? cart.shipping.value : 0)) }}</strong>
      </div>

      <p v-if="error" class="error">{{ error }}</p>
      <button class="kv-btn kv-btn-dark full" type="submit" :disabled="loading">
        {{ loading ? 'Envoi…' : 'Confirmer la commande' }}
      </button>
    </form>

    <Teleport to="body">
      <div v-if="consentOpen" class="consent-backdrop" @click.self="consentOpen = false">
        <div class="consent" role="dialog" aria-modal="true" aria-labelledby="consent-title">
          <div class="consent-icon">📍</div>
          <h3 id="consent-title">Partager votre position ?</h3>
          <p>KINOVA a besoin de votre position actuelle pour que le livreur trouve votre adresse exacte.</p>
          <ul>
            <li>Utilisée une seule fois, pour cette commande</li>
            <li>Visible uniquement par la boutique et le livreur</li>
            <li>Aucun suivi en arrière-plan</li>
          </ul>
          <div class="consent-actions">
            <button type="button" class="kv-btn" @click="consentOpen = false">Plus tard</button>
            <button type="button" class="kv-btn kv-btn-dark" @click="locate">Autoriser</button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.page {
  padding: 1.1rem 0 2rem;
}
.form {
  display: grid;
  gap: 0.85rem;
}
label {
  display: grid;
  gap: 0.35rem;
  font-size: 0.78rem;
  font-weight: 700;
  color: var(--kv-muted);
}
.order-items-recap {
  background: var(--kv-surface);
  border-radius: 14px;
  border: 1px solid rgba(197, 160, 128, 0.2);
  padding: 0.75rem 1rem;
  display: flex;
  flex-direction: column;
  gap: 0.6rem;
}
.recap-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.82rem;
  padding-bottom: 0.45rem;
  border-bottom: 1px dashed rgba(197, 160, 128, 0.25);
}
.recap-row:last-child {
  padding-bottom: 0;
  border-bottom: none;
}
.recap-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.recap-name {
  font-weight: 700;
  color: var(--kv-brown);
}
.recap-variants {
  font-size: 0.72rem;
  color: var(--kv-muted);
}
.recap-price {
  font-weight: 800;
  color: var(--kv-gold);
}
.sum {
  margin-top: 0.35rem;
  padding: 0.9rem 1rem;
  background: var(--kv-surface);
  border-radius: 14px;
  border: 1px solid rgba(197, 160, 128, 0.2);
}
.error {
  color: #8b3a2f;
  font-size: 0.85rem;
}
.toggle {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.8rem 1rem;
  background: var(--kv-surface);
  border-radius: 14px;
  border: 1px solid rgba(197, 160, 128, 0.3);
  cursor: pointer;
}
.toggle input {
  width: 20px;
  height: 20px;
  accent-color: var(--kv-gold);
}
.toggle span,
.geo > div,
.pay {
  display: grid;
  gap: 2px;
}
.toggle strong,
.geo strong,
.pay strong {
  color: var(--kv-brown);
  font-size: 0.85rem;
}
.toggle small,
.geo small,
.pay small {
  font-weight: 500;
  color: var(--kv-muted);
}
.geo,
.pay {
  padding: 0.8rem 1rem;
  background: var(--kv-surface);
  border-radius: 14px;
  border: 1px solid rgba(197, 160, 128, 0.3);
}
.geo {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 0.75rem;
}
.pay {
  border-color: var(--kv-brown);
}
.note {
  margin: 0;
  padding: 0.7rem 0.9rem;
  border-radius: 12px;
  background: rgba(212, 175, 55, 0.12);
  color: var(--kv-brown);
  font-size: 0.78rem;
}
.full {
  width: 100%;
}
.consent-backdrop {
  position: fixed;
  inset: 0;
  z-index: 1000;
  display: flex;
  align-items: flex-end;
  justify-content: center;
  background: rgba(20, 12, 7, 0.55);
}
.consent {
  width: 100%;
  max-width: 440px;
  padding: 1.4rem 1.3rem 1.2rem;
  border-radius: 22px 22px 0 0;
  background: var(--kv-surface, #fff);
  text-align: center;
}
@media (min-width: 640px) {
  .consent-backdrop {
    align-items: center;
  }
  .consent {
    border-radius: 22px;
  }
}
.consent-icon {
  font-size: 1.8rem;
}
.consent h3 {
  margin: 0.4rem 0 0.5rem;
  color: var(--kv-brown);
  font-size: 1.05rem;
}
.consent p {
  margin: 0 0 0.8rem;
  color: var(--kv-muted);
  font-size: 0.85rem;
  line-height: 1.4;
}
.consent ul {
  margin: 0 0 1.1rem;
  padding: 0;
  list-style: none;
  display: grid;
  gap: 0.35rem;
  text-align: left;
  font-size: 0.8rem;
  color: var(--kv-brown);
}
.consent li::before {
  content: '✓';
  margin-right: 0.5rem;
  color: var(--kv-gold);
  font-weight: 800;
}
.consent-actions {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 0.6rem;
}
</style>
