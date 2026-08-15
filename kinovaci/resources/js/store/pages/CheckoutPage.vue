<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { getToken } from '../api/client'
import { formatMoney } from '../lib/format'
import { useAuth } from '../state/auth'
import { useCart } from '../state/cart'

const router = useRouter()
const auth = useAuth()
const cart = useCart()
const error = ref('')
const loading = ref(false)

const form = reactive({
  customer_name: '',
  customer_phone: '',
  customer_email: '',
  address: '',
  city: '',
  payment_method: 'cod' as 'cod' | 'card',
  notes: '',
})

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
  if (!getToken()) {
    router.replace({ name: 'auth', query: { redirect: '/commande' } })
    return
  }
  if (!cart.state.items.length) {
    router.push({ name: 'cart' })
    return
  }
  error.value = ''
  loading.value = true
  try {
    const order = await cart.placeOrder({
      customer_name: form.customer_name,
      customer_phone: form.customer_phone,
      customer_email: form.customer_email || undefined,
      address: form.address,
      city: form.city,
      payment_method: form.payment_method,
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
      <label>Adresse<input v-model="form.address" class="kv-input" required /></label>
      <label>Ville<input v-model="form.city" class="kv-input" required /></label>
      <label>
        Paiement
        <select v-model="form.payment_method" class="kv-input">
          <option value="cod">Paiement à la livraison</option>
          <option value="card">Carte</option>
        </select>
      </label>
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
        Total à payer : <strong>{{ formatMoney(cart.total.value) }}</strong>
      </div>

      <p v-if="error" class="error">{{ error }}</p>
      <button class="kv-btn kv-btn-dark full" type="submit" :disabled="loading">
        {{ loading ? 'Envoi…' : 'Confirmer la commande' }}
      </button>
    </form>
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
.full {
  width: 100%;
}
</style>
