<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import TypewriterHint from './TypewriterHint.vue'
import { getToken } from '../api/client'
import { useAuth } from '../state/auth'
import { useCart } from '../state/cart'
import { resolveMediaUrl } from '../lib/format'

const route = useRoute()
const router = useRouter()
const auth = useAuth()
const cart = useCart()

const firstName = computed(() => {
  const name = auth.state.user?.name?.trim()
  return name ? name.split(' ')[0] : null
})

const hideChrome = computed(() => !!route.meta.hideChrome)
const cartCount = computed(() => cart.itemCount.value)
const loggedIn = computed(() => !!getToken())

const tabs = [
  { name: 'home', label: 'Accueil', icon: '⌂' },
  { name: 'catalog', label: 'Boutique', icon: '▦' },
  { name: 'cart', label: 'Panier', icon: '🛒', cart: true },
  { name: 'favorites', label: 'Favoris', icon: '♡' },
  { name: 'account', label: 'Compte', icon: '◎', account: true },
] as const

function go(tab: (typeof tabs)[number]) {
  if (tab.account) {
    if (loggedIn.value) router.push({ name: 'account' })
    else router.push({ name: 'auth', query: { redirect: '/compte' } })
    return
  }
  router.push({ name: tab.name })
}

function isActive(tab: (typeof tabs)[number]) {
  if (tab.account) return route.name === 'account' || route.name === 'auth' || route.name === 'edit-profile'
  return route.name === tab.name
}
</script>

<template>
  <div class="shell">
    <header v-if="!hideChrome" class="top">
      <div class="kv-container top-inner">
        <div class="brand-row">
          <button class="logo" type="button" @click="router.push({ name: 'home' })">
            <img src="/favicon.png" alt="KINOVA" />
          </button>
          <div class="greet">
            <p>{{ firstName ? `Bonjour ${firstName}` : 'Bienvenue chez' }}</p>
            <h1 class="kv-display">KINOVA</h1>
          </div>
          <button class="bell" type="button" @click="router.push({ name: 'notifications' })" aria-label="Notifications">
            🔔
          </button>
        </div>

        <button class="search" type="button" @click="router.push({ name: 'search' })">
          <span class="icon">⌕</span>
          <TypewriterHint
            class="placeholder"
            :phrases="[
              'Un soin, un sac, une senteur...',
              'Rouge, parfum, senteur...',
              'Mode, beauté, maison...',
              'Cherchez votre univers...',
            ]"
          />
          <span class="tune">☰</span>
        </button>
      </div>
    </header>

    <main class="main" :class="{ 'no-pad': hideChrome }">
      <slot />
    </main>

    <nav v-if="!hideChrome" class="bottom" aria-label="Navigation principale">
      <button
        v-for="tab in tabs"
        :key="tab.name"
        type="button"
        class="tab"
        :class="{ active: isActive(tab), cart: tab.cart }"
        @click="go(tab)"
      >
        <span v-if="tab.cart" class="cart-bubble">
          🛒
          <i v-if="cartCount">{{ cartCount }}</i>
        </span>
        <span v-else-if="tab.account && auth.state.user?.avatar_url" class="avatar-wrap">
          <img class="avatar" :src="resolveMediaUrl(auth.state.user.avatar_url)" alt="" />
        </span>
        <span v-else class="ico">{{ tab.icon }}</span>
        <em>{{ tab.label }}</em>
      </button>
    </nav>
  </div>
</template>

<style scoped>
.shell {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  background: var(--kv-bg);
}
.top {
  background: radial-gradient(circle at 20% -40%, #3a281c, #2c1e14 40%, #1b110b 100%);
  border-radius: 0 0 34px 34px;
  padding: 0.85rem 0 1.35rem;
  color: var(--kv-cream);
  position: sticky;
  top: 0;
  z-index: 40;
}
.top-inner {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}
.brand-row {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}
.logo {
  width: 42px;
  height: 42px;
  border-radius: 14px;
  border: 1px solid rgba(197, 160, 128, 0.4);
  background: rgba(255, 255, 255, 0.06);
  padding: 4px;
  cursor: pointer;
}
.logo img {
  width: 100%;
  height: 100%;
  object-fit: contain;
}
.greet {
  flex: 1;
  min-width: 0;
}
.greet p {
  margin: 0;
  color: var(--kv-sand);
  font-size: 0.72rem;
  letter-spacing: 0.04em;
}
.greet h1 {
  margin: 0;
  font-size: 1.2rem;
  letter-spacing: 0.28em;
  color: #f7e7ce;
}
.bell {
  width: 40px;
  height: 40px;
  border-radius: 999px;
  border: 1px solid rgba(197, 160, 128, 0.4);
  background: rgba(255, 255, 255, 0.08);
  cursor: pointer;
}
.search {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  width: 100%;
  padding: 0.85rem 1rem;
  border-radius: 16px;
  border: 1px solid rgba(197, 160, 128, 0.35);
  background: rgba(255, 255, 255, 0.09);
  color: rgba(193, 168, 149, 0.95);
  cursor: pointer;
  text-align: left;
}
.placeholder {
  flex: 1;
  font-size: 0.82rem;
  overflow: hidden;
}
.tune {
  background: linear-gradient(135deg, #d4af37, #c5a080);
  color: var(--kv-brown);
  width: 26px;
  height: 26px;
  border-radius: 8px;
  display: grid;
  place-items: center;
  font-size: 0.75rem;
  font-weight: 800;
}
.main {
  flex: 1;
  padding-bottom: 5.5rem;
}
.main.no-pad {
  padding-bottom: 0;
}
.bottom {
  position: fixed;
  left: 50%;
  transform: translateX(-50%);
  bottom: 0;
  width: min(560px, 100%);
  display: grid;
  grid-template-columns: repeat(5, minmax(0, 1fr));
  align-items: end;
  gap: 0;
  padding: 0.35rem 0.25rem calc(0.45rem + env(safe-area-inset-bottom));
  background: rgba(253, 251, 247, 0.96);
  backdrop-filter: blur(12px);
  border-top: 1px solid rgba(197, 160, 128, 0.22);
  z-index: 50;
}
.tab {
  position: relative;
  z-index: 2;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: flex-end;
  gap: 0.12rem;
  min-height: 52px;
  border: none;
  background: transparent;
  color: var(--kv-muted);
  cursor: pointer;
  padding: 0.25rem 0.1rem;
  font-family: inherit;
}
.tab em {
  font-style: normal;
  font-size: 0.58rem;
  font-weight: 700;
  letter-spacing: 0.02em;
}
.tab .ico {
  font-size: 1.05rem;
  line-height: 1;
}
.tab.active {
  color: var(--kv-brown);
}
.tab.cart {
  z-index: 1;
  margin-top: -1.2rem;
}
.cart-bubble {
  position: relative;
  width: 54px;
  height: 54px;
  border-radius: 999px;
  display: grid;
  place-items: center;
  background: linear-gradient(135deg, #3e2723, #251614);
  color: var(--kv-gold-light);
  font-size: 1.2rem;
  box-shadow: 0 8px 18px rgba(62, 39, 35, 0.28);
  border: 2px solid rgba(212, 175, 55, 0.55);
  pointer-events: none;
}
.cart-bubble i {
  position: absolute;
  top: -2px;
  right: -2px;
  min-width: 18px;
  height: 18px;
  padding: 0 4px;
  border-radius: 999px;
  background: var(--kv-gold-rich);
  color: var(--kv-brown);
  font-style: normal;
  font-size: 0.65rem;
  font-weight: 800;
  display: grid;
  place-items: center;
}
.avatar-wrap {
  width: 22px;
  height: 22px;
  border-radius: 999px;
  overflow: hidden;
  border: 1px solid rgba(197, 160, 128, 0.5);
}
.avatar {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
</style>
