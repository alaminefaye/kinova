<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { api } from '../api/client'
import { useAuth } from '../state/auth'
import KinovaLoader from '../components/KinovaLoader.vue'

const router = useRouter()
const auth = useAuth()
const help = ref<{
  faqs?: { q: string; a: string }[]
  phone?: string
  email?: string
  hours?: string
} | null>(null)
const loading = ref(true)
const sent = ref(false)
const error = ref('')
const form = reactive({
  name: '',
  email: '',
  phone: '',
  subject: '',
  message: '',
})

onMounted(async () => {
  const u = auth.state.user
  if (u) {
    form.name = u.name || ''
    form.email = u.email || ''
    form.phone = u.phone || ''
  }
  try {
    const res = await api<{ data: any }>('/help')
    help.value = res.data || res
  } catch {
    help.value = null
  } finally {
    loading.value = false
  }
})

async function submit() {
  error.value = ''
  sent.value = false
  try {
    await api('/contact', {
      method: 'POST',
      json: { ...form },
    })
    sent.value = true
    form.subject = ''
    form.message = ''
  } catch (e: any) {
    error.value = e?.message || 'Envoi impossible'
  }
}
</script>

<template>
  <div class="page">
    <header class="head">
      <div class="kv-container row">
        <button class="round" type="button" @click="router.back()">←</button>
        <h1 class="kv-display">Aide & contact</h1>
      </div>
    </header>

    <div class="kv-container body">
      <KinovaLoader v-if="loading" compact message="Chargement" :size="58" />

      <section v-if="!loading && help" class="card">
        <h3>Nous joindre</h3>
        <p v-if="help.phone">Tél. {{ help.phone }}</p>
        <p v-if="help.email">{{ help.email }}</p>
        <p v-if="help.hours">{{ help.hours }}</p>
      </section>

      <section v-if="help?.faqs?.length" class="card">
        <h3>FAQ</h3>
        <details v-for="(item, i) in help.faqs" :key="i">
          <summary>{{ item.q }}</summary>
          <p>{{ item.a }}</p>
        </details>
      </section>

      <section class="card">
        <h3>Écrire un message</h3>
        <form class="form" @submit.prevent="submit">
          <label>Nom<input v-model="form.name" class="kv-input" required /></label>
          <label>Email<input v-model="form.email" type="email" class="kv-input" required /></label>
          <label>Téléphone<input v-model="form.phone" class="kv-input" /></label>
          <label>Sujet<input v-model="form.subject" class="kv-input" required /></label>
          <label>Message<textarea v-model="form.message" class="kv-input" rows="4" required /></label>
          <p v-if="error" class="error">{{ error }}</p>
          <p v-if="sent" class="ok">Message envoyé. Merci !</p>
          <button class="kv-btn kv-btn-dark" type="submit">Envoyer</button>
        </form>
      </section>
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
  font-size: 1.25rem;
  color: #f7e7ce;
}
.body {
  padding: 1rem 0 2rem;
}
.muted {
  color: var(--kv-muted);
}
.card {
  background: var(--kv-surface);
  border-radius: 18px;
  padding: 1rem;
  border: 1px solid rgba(197, 160, 128, 0.18);
  margin-bottom: 1rem;
  box-shadow: var(--kv-shadow);
}
.card h3 {
  margin: 0 0 0.65rem;
  font-size: 1rem;
}
.card > p {
  margin: 0.25rem 0;
  color: var(--kv-muted);
  font-size: 0.88rem;
}
details {
  border-top: 1px solid rgba(197, 160, 128, 0.15);
  padding: 0.65rem 0;
}
summary {
  cursor: pointer;
  font-weight: 700;
  font-size: 0.88rem;
}
details p {
  margin: 0.45rem 0 0;
  color: var(--kv-muted);
  font-size: 0.84rem;
  line-height: 1.45;
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
.error {
  color: #8b3a2f;
}
.ok {
  color: #2f6b4f;
  font-weight: 700;
}
</style>
