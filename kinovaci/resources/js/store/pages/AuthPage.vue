<script setup lang="ts">
import { reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuth } from '../state/auth'
import { useFavorites } from '../state/favorites'

const route = useRoute()
const router = useRouter()
const auth = useAuth()
const favorites = useFavorites()

const mode = ref<'login' | 'register'>('login')
const error = ref('')
const form = reactive({
  name: '',
  phone: '',
  email: '',
  login: '',
  password: '',
})

async function submit() {
  error.value = ''
  try {
    if (mode.value === 'login') {
      await auth.login(form.login, form.password)
    } else {
      await auth.register({
        name: form.name,
        phone: form.phone,
        email: form.email || undefined,
        password: form.password,
      })
    }
    await favorites.sync()
    await favorites.loadFromApi()
    const redirect = (route.query.redirect as string) || '/'
    router.replace(redirect)
  } catch (e: any) {
    error.value = e?.message || 'Erreur d’authentification'
  }
}
</script>

<template>
  <div class="page">
    <div class="panel kv-container">
      <p class="eyebrow">KINOVA</p>
      <h1 class="kv-display">{{ mode === 'login' ? 'Connexion' : 'Créer un compte' }}</h1>
      <p class="sub">Même compte que sur l’application mobile.</p>

      <form @submit.prevent="submit">
        <template v-if="mode === 'register'">
          <label>Nom<input v-model="form.name" class="kv-input" required /></label>
          <label>Téléphone<input v-model="form.phone" class="kv-input" required /></label>
          <label>Email (optionnel)<input v-model="form.email" type="email" class="kv-input" /></label>
        </template>
        <template v-else>
          <label>Email ou téléphone<input v-model="form.login" class="kv-input" required /></label>
        </template>
        <label>Mot de passe<input v-model="form.password" type="password" class="kv-input" required minlength="8" /></label>

        <p v-if="error" class="error">{{ error }}</p>
        <button class="kv-btn kv-btn-dark full" type="submit" :disabled="auth.state.loading">
          {{ auth.state.loading ? 'Patientez…' : mode === 'login' ? 'Se connecter' : 'S’inscrire' }}
        </button>
      </form>

      <button class="switch" type="button" @click="mode = mode === 'login' ? 'register' : 'login'">
        {{ mode === 'login' ? 'Pas encore de compte ? S’inscrire' : 'Déjà un compte ? Se connecter' }}
      </button>
    </div>
  </div>
</template>

<style scoped>
.page {
  min-height: 100vh;
  background: radial-gradient(circle at 20% -20%, #3a281c, #1b110b 55%);
  padding: 2.5rem 0 3rem;
  color: var(--kv-cream);
}
.panel {
  background: var(--kv-bg);
  color: var(--kv-brown);
  border-radius: 24px;
  padding: 1.5rem 1.15rem 1.75rem;
  box-shadow: var(--kv-shadow);
}
.eyebrow {
  margin: 0;
  color: var(--kv-gold);
  font-size: 0.7rem;
  font-weight: 800;
  letter-spacing: 0.22em;
}
h1 {
  margin: 0.35rem 0 0.35rem;
  font-size: 1.7rem;
}
.sub {
  margin: 0 0 1.2rem;
  color: var(--kv-muted);
  font-size: 0.85rem;
}
form {
  display: grid;
  gap: 0.8rem;
}
label {
  display: grid;
  gap: 0.3rem;
  font-size: 0.75rem;
  font-weight: 700;
  color: var(--kv-muted);
}
.full {
  width: 100%;
  margin-top: 0.35rem;
}
.error {
  color: #8b3a2f;
  font-size: 0.85rem;
}
.switch {
  margin-top: 1rem;
  width: 100%;
  border: none;
  background: transparent;
  color: var(--kv-gold);
  font-weight: 700;
  font-size: 0.82rem;
  cursor: pointer;
}
</style>
