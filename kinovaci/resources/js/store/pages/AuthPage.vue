<script setup lang="ts">
import { reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import AnimatedLogoBadge from '../components/AnimatedLogoBadge.vue'
import { useAuth } from '../state/auth'
import { useFavorites } from '../state/favorites'

const route = useRoute()
const router = useRouter()
const auth = useAuth()
const favorites = useFavorites()

const registerMode = ref(false)
const obscure = ref(true)
const error = ref('')
const form = reactive({
  name: '',
  phone: '',
  email: '',
  login: '',
  password: '',
})

function switchMode(register: boolean) {
  if (auth.state.loading) return
  registerMode.value = register
  error.value = ''
}

async function submit() {
  error.value = ''
  try {
    if (registerMode.value) {
      await auth.register({
        name: form.name,
        phone: form.phone,
        email: form.email || undefined,
        password: form.password,
      })
    } else {
      await auth.login(form.login, form.password)
    }
    try {
      await favorites.sync()
      await favorites.loadFromApi()
    } catch {
      /* ignore */
    }
    const redirect = (route.query.redirect as string) || '/compte'
    router.replace(redirect)
  } catch (e: any) {
    error.value = e?.message || 'Connexion impossible. Vérifiez votre réseau.'
  }
}

function goBack() {
  if (window.history.length > 1) router.back()
  else router.push({ name: 'home' })
}
</script>

<template>
  <div class="auth">
    <div class="glow" />

    <button class="back" type="button" @click="goBack" aria-label="Retour">←</button>

    <header class="brand">
      <div class="logo-wrap">
        <AnimatedLogoBadge :size="84" />
      </div>
      <h1 class="kv-display">K I N O V A</h1>
      <p class="tag">ESPACE PRIVILÈGE</p>
    </header>

    <section class="sheet">
      <div class="toggle">
        <button type="button" :class="{ on: !registerMode }" @click="switchMode(false)">Connexion</button>
        <button type="button" :class="{ on: registerMode }" @click="switchMode(true)">Inscription</button>
      </div>

      <h2 class="kv-display">{{ registerMode ? 'Rejoignez la Maison' : 'Bon retour parmi nous' }}</h2>
      <p class="lead">
        {{
          registerMode
            ? 'Créez votre compte et cumulez vos points VIP.'
            : 'Retrouvez vos favoris, commandes et avantages.'
        }}
      </p>

      <form @submit.prevent="submit">
        <template v-if="registerMode">
          <label class="field">
            <span class="ico">◎</span>
            <input v-model="form.name" placeholder="Nom complet" required />
          </label>
          <label class="field">
            <span class="ico">☎</span>
            <input v-model="form.phone" placeholder="Numéro de téléphone" required minlength="8" />
          </label>
          <label class="field">
            <span class="ico">✉</span>
            <input v-model="form.email" type="email" placeholder="Email (optionnel)" />
          </label>
        </template>
        <template v-else>
          <label class="field">
            <span class="ico">◎</span>
            <input v-model="form.login" placeholder="Email ou numéro de téléphone" required />
          </label>
        </template>

        <label class="field">
          <span class="ico">⌂</span>
          <input
            v-model="form.password"
            :type="obscure ? 'password' : 'text'"
            placeholder="Mot de passe"
            required
            minlength="6"
          />
          <button
            class="eye"
            type="button"
            @click="obscure = !obscure"
            :aria-label="obscure ? 'Afficher le mot de passe' : 'Masquer le mot de passe'"
          >
            <!-- eye / eye-off -->
            <svg v-if="obscure" viewBox="0 0 24 24" fill="none" aria-hidden="true">
              <path
                d="M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12Z"
                stroke="currentColor"
                stroke-width="1.7"
                stroke-linecap="round"
                stroke-linejoin="round"
              />
              <circle cx="12" cy="12" r="3.2" stroke="currentColor" stroke-width="1.7" />
            </svg>
            <svg v-else viewBox="0 0 24 24" fill="none" aria-hidden="true">
              <path
                d="M3 3l18 18M10.5 6.2A8.4 8.4 0 0 1 12 5.5C18 5.5 21.5 12 21.5 12a14.7 14.7 0 0 1-3.1 3.9M7.2 7.3C4.7 8.9 2.5 12 2.5 12a14.8 14.8 0 0 0 7.4 5.7"
                stroke="currentColor"
                stroke-width="1.7"
                stroke-linecap="round"
                stroke-linejoin="round"
              />
              <path
                d="M9.9 9.9a3.2 3.2 0 0 0 4.5 4.5"
                stroke="currentColor"
                stroke-width="1.7"
                stroke-linecap="round"
              />
            </svg>
          </button>
        </label>

        <div v-if="error" class="error">{{ error }}</div>

        <button class="gold" type="submit" :disabled="auth.state.loading">
          {{
            auth.state.loading
              ? 'Patientez…'
              : registerMode
                ? 'CRÉER MON COMPTE'
                : 'SE CONNECTER'
          }}
        </button>
      </form>

      <div class="sep"><span>EVERYTHING YOU LOVE</span></div>

      <p class="switch">
        {{ registerMode ? 'Déjà membre ?' : 'Nouveau chez KINOVA ?' }}
        <button type="button" @click="switchMode(!registerMode)">
          {{ registerMode ? 'Connexion' : 'Créer un compte' }}
        </button>
      </p>
    </section>
  </div>
</template>

<style scoped>
.auth {
  min-height: 100vh;
  background: radial-gradient(circle at 50% -20%, #2c1e14, #1b110b 50%, #0f0a06 100%);
  color: var(--kv-cream);
  display: flex;
  flex-direction: column;
  position: relative;
  overflow: hidden;
}
.glow {
  position: absolute;
  top: 4%;
  left: 50%;
  transform: translateX(-50%);
  width: 220px;
  height: 220px;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(212, 175, 55, 0.28), rgba(197, 160, 128, 0.1), transparent 70%);
  pointer-events: none;
}
.back {
  position: relative;
  z-index: 2;
  align-self: flex-start;
  margin: 0.75rem 0.5rem 0;
  width: 42px;
  height: 42px;
  border: none;
  background: transparent;
  color: var(--kv-sand);
  font-size: 1.2rem;
  cursor: pointer;
}
.brand {
  position: relative;
  z-index: 2;
  text-align: center;
  padding: 0.25rem 1rem 1.25rem;
}
.logo-wrap {
  width: 84px;
  height: 84px;
  margin: 0 auto 1rem;
  display: grid;
  place-items: center;
}
.brand h1 {
  margin: 0;
  font-size: 1.5rem;
  letter-spacing: 0.5em;
  color: #f7e7ce;
  text-shadow: 0 0 14px rgba(212, 175, 55, 0.4);
}
.tag {
  margin: 0.4rem 0 0;
  color: #c5a080;
  font-size: 0.6rem;
  font-weight: 600;
  letter-spacing: 0.35em;
}
.sheet {
  position: relative;
  z-index: 2;
  flex: 1;
  background: var(--kv-bg);
  color: var(--kv-brown);
  border-radius: 32px 32px 0 0;
  border-top: 1px solid rgba(197, 160, 128, 0.5);
  box-shadow: 0 -8px 30px rgba(0, 0, 0, 0.4);
  padding: 1.6rem 1.4rem 2rem;
  width: min(480px, 100%);
  margin: 0 auto;
}
.toggle {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 0.25rem;
  padding: 0.25rem;
  background: var(--kv-surface-muted);
  border-radius: 14px;
  margin-bottom: 1.35rem;
}
.toggle button {
  border: none;
  background: transparent;
  border-radius: 12px;
  padding: 0.7rem;
  font-weight: 700;
  font-size: 0.78rem;
  letter-spacing: 0.04em;
  color: var(--kv-muted);
  cursor: pointer;
}
.toggle button.on {
  background: linear-gradient(135deg, #3e2723, #251614);
  color: var(--kv-gold-light);
}
.sheet h2 {
  margin: 0 0 0.4rem;
  font-size: 1.5rem;
  font-weight: 600;
}
.lead {
  margin: 0 0 1.25rem;
  color: var(--kv-muted);
  font-size: 0.8rem;
  line-height: 1.4;
}
form {
  display: grid;
  gap: 0.85rem;
}
.field {
  display: flex;
  align-items: center;
  gap: 0.55rem;
  background: var(--kv-cream);
  border: 1px solid rgba(197, 160, 128, 0.35);
  border-radius: 14px;
  padding: 0.15rem 0.75rem;
}
.field:focus-within {
  border-color: var(--kv-gold);
  box-shadow: 0 0 0 3px rgba(197, 160, 128, 0.16);
}
.field .ico {
  color: var(--kv-sand);
  font-size: 0.95rem;
}
.field input {
  flex: 1;
  border: none;
  background: transparent;
  padding: 0.85rem 0;
  color: var(--kv-brown);
  outline: none;
  font-size: 0.9rem;
}
.eye {
  border: none;
  background: transparent;
  color: var(--kv-sand);
  width: 34px;
  height: 34px;
  display: grid;
  place-items: center;
  cursor: pointer;
  padding: 0;
  flex-shrink: 0;
}
.eye svg {
  width: 20px;
  height: 20px;
  display: block;
}
.error {
  display: flex;
  gap: 0.55rem;
  align-items: flex-start;
  background: #fdecea;
  border: 1px solid rgba(229, 115, 115, 0.5);
  color: #c62828;
  border-radius: 12px;
  padding: 0.75rem 0.9rem;
  font-size: 0.78rem;
}
.gold {
  margin-top: 0.35rem;
  width: 100%;
  border: none;
  border-radius: 14px;
  padding: 1rem 1.2rem;
  font-weight: 800;
  letter-spacing: 0.12em;
  font-size: 0.78rem;
  cursor: pointer;
  color: var(--kv-brown);
  background: linear-gradient(135deg, #d4af37, #c5a080, #e8d5b7);
  box-shadow: 0 8px 20px rgba(62, 39, 35, 0.18);
}
.gold:disabled {
  opacity: 0.7;
  cursor: wait;
}
.sep {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin: 1.15rem 0 0.9rem;
  color: var(--kv-sand);
  font-size: 0.55rem;
  font-weight: 600;
  letter-spacing: 0.2em;
}
.sep::before,
.sep::after {
  content: '';
  flex: 1;
  height: 1px;
  background: rgba(193, 168, 149, 0.4);
}
.switch {
  text-align: center;
  margin: 0;
  color: var(--kv-muted);
  font-size: 0.8rem;
}
.switch button {
  border: none;
  background: transparent;
  color: var(--kv-brown);
  font-weight: 700;
  text-decoration: underline;
  text-decoration-color: var(--kv-gold);
  cursor: pointer;
  font-size: inherit;
}
</style>
