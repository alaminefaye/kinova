<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { formatMoney } from '../lib/format'

const route = useRoute()
const router = useRouter()
const reference = computed(() => String(route.params.reference || ''))
const total = computed(() => Number(route.query.total || 0))
</script>

<template>
  <div class="page kv-container">
    <div class="card">
      <p class="ok">✓</p>
      <h1 class="kv-display">Commande confirmée</h1>
      <p>
        Merci pour votre confiance.<br />
        N° {{ reference }}
        <template v-if="total"> — {{ formatMoney(total) }}</template>
      </p>
      <button class="kv-btn kv-btn-primary" type="button" @click="router.push({ name: 'home' })">
        Retour à l’accueil
      </button>
    </div>
  </div>
</template>

<style scoped>
.page {
  padding: 2.5rem 0;
}
.card {
  text-align: center;
  background: var(--kv-surface);
  border-radius: 22px;
  padding: 2rem 1.25rem;
  border: 1px solid rgba(197, 160, 128, 0.2);
  box-shadow: var(--kv-shadow);
}
.ok {
  width: 54px;
  height: 54px;
  margin: 0 auto 0.85rem;
  border-radius: 999px;
  display: grid;
  place-items: center;
  background: linear-gradient(135deg, #d4af37, #c5a080);
  color: var(--kv-brown);
  font-size: 1.4rem;
  font-weight: 800;
}
h1 {
  margin: 0 0 0.55rem;
}
p {
  color: var(--kv-muted);
  line-height: 1.5;
  margin: 0 0 1.25rem;
}
</style>
