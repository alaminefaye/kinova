<script setup lang="ts">
import { useRouter } from 'vue-router'
import SoftImage from '../components/SoftImage.vue'
import { formatMoney } from '../lib/format'
import { useCart } from '../state/cart'

const router = useRouter()
const cart = useCart()
</script>

<template>
  <div class="page kv-container">
    <div class="kv-section-title">
      <h2>Panier</h2>
    </div>

    <div v-if="!cart.state.items.length" class="empty">
      <p>Votre panier est vide.</p>
      <button class="kv-btn kv-btn-primary" type="button" @click="router.push({ name: 'catalog' })">
        Explorer la boutique
      </button>
    </div>

    <template v-else>
      <article
        v-for="(item, idx) in cart.state.items"
        :key="item.product.id + (item.selectedSize || '') + (item.selectedColor || '')"
        class="line"
      >
        <div class="thumb">
          <SoftImage :url="item.product.imageUrl" :alt="item.product.name" />
        </div>
        <div class="info">
          <h3>{{ item.product.name }}</h3>
          <div v-if="item.selectedSize || item.selectedColor" class="variant-tags">
            <span v-if="item.selectedSize" class="variant-tag">Taille : {{ item.selectedSize }}</span>
            <span v-if="item.selectedColor" class="variant-tag">Couleur : {{ item.selectedColor }}</span>
          </div>
          <div v-if="item.product.promoPrice && item.product.promoPrice < item.product.price" class="cart-prices">
            <span class="old-price">{{ formatMoney(item.product.price) }}</span>
            <p class="promo-price">{{ formatMoney(item.product.promoPrice) }}</p>
          </div>
          <p v-else>{{ formatMoney(item.product.price) }}</p>
          <div class="qty">
            <button type="button" @click="cart.setQuantity(idx, item.quantity - 1)">−</button>
            <span>{{ item.quantity }}</span>
            <button type="button" @click="cart.setQuantity(idx, item.quantity + 1)">+</button>
          </div>
        </div>
        <div class="side">
          <strong>{{ formatMoney((item.product.promoPrice && item.product.promoPrice < item.product.price ? item.product.promoPrice : item.product.price) * item.quantity) }}</strong>
          <button class="rm" type="button" @click="cart.remove(idx)">Retirer</button>
        </div>
      </article>

      <section class="summary">
        <div><span>Articles</span><strong>{{ formatMoney(cart.subtotal.value) }}</strong></div>
        <div>
          <span>Livraison</span>
          <strong>{{ cart.shipping.value === 0 ? 'Offerte' : formatMoney(cart.shipping.value) }}</strong>
        </div>
        <div class="total"><span>Total</span><strong>{{ formatMoney(cart.total.value) }}</strong></div>
      </section>

      <button class="kv-btn kv-btn-dark full" type="button" @click="router.push({ name: 'checkout' })">
        Commander
      </button>
    </template>
  </div>
</template>

<style scoped>
.page {
  padding: 1.1rem 0 2rem;
}
.empty {
  text-align: center;
  padding: 2.5rem 0;
  color: var(--kv-muted);
}
.line {
  display: grid;
  grid-template-columns: 84px 1fr auto;
  gap: 0.75rem;
  background: var(--kv-surface);
  border: 1px solid rgba(197, 160, 128, 0.18);
  border-radius: 16px;
  padding: 0.75rem;
  margin-bottom: 0.75rem;
  box-shadow: var(--kv-shadow);
}
.thumb {
  width: 84px;
  height: 84px;
  border-radius: 12px;
  overflow: hidden;
}
.info h3 {
  margin: 0 0 0.25rem;
  font-size: 0.88rem;
}
.variant-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 0.35rem;
  margin-bottom: 0.35rem;
}
.variant-tag {
  font-size: 0.7rem;
  background: var(--kv-surface-muted);
  color: var(--kv-brown);
  padding: 0.15rem 0.45rem;
  border-radius: 6px;
  border: 1px solid rgba(197, 160, 128, 0.25);
  font-weight: 600;
}
.cart-prices {
  display: flex;
  align-items: baseline;
  gap: 0.45rem;
}
.old-price {
  font-size: 0.72rem;
  color: #9e8e82;
  text-decoration: line-through;
  font-weight: 500;
}
.promo-price {
  color: #b91c1c !important;
  font-weight: 800 !important;
}
.info p {
  margin: 0;
  color: var(--kv-gold);
  font-weight: 700;
  font-size: 0.8rem;
}
.qty {
  display: inline-flex;
  align-items: center;
  gap: 0.45rem;
  margin-top: 0.55rem;
  background: var(--kv-surface-muted);
  border-radius: 999px;
  padding: 0.15rem 0.35rem;
}
.qty button {
  width: 26px;
  height: 26px;
  border: none;
  border-radius: 999px;
  background: var(--kv-brown);
  color: var(--kv-cream);
  cursor: pointer;
}
.side {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  justify-content: space-between;
  font-size: 0.82rem;
}
.rm {
  border: none;
  background: transparent;
  color: var(--kv-muted);
  cursor: pointer;
  font-size: 0.72rem;
}
.summary {
  background: var(--kv-surface);
  border-radius: 16px;
  padding: 1rem;
  margin: 1rem 0;
  border: 1px solid rgba(197, 160, 128, 0.18);
}
.summary div {
  display: flex;
  justify-content: space-between;
  margin-bottom: 0.45rem;
  color: var(--kv-muted);
  font-size: 0.86rem;
}
.summary .total {
  margin-top: 0.55rem;
  padding-top: 0.55rem;
  border-top: 1px solid rgba(197, 160, 128, 0.2);
  color: var(--kv-brown);
  font-size: 1rem;
}
.full {
  width: 100%;
}
</style>
