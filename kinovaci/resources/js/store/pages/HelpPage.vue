<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { api } from '../api/client'

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
  <div class="page kv-container">
    <div class="kv-section-title">
      <h2>Aide & contact</h2>
    </div>

    <p v-if="loading" class="muted">Chargement…</p>

    <section v-if="help" class="card">
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
</template>

<style scoped>
.page {
  padding: 1.1rem 0 2rem;
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
