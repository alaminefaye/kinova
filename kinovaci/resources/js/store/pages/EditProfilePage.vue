<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { api, getToken } from '../api/client'
import { resolveMediaUrl } from '../lib/format'
import { useAuth } from '../state/auth'

const router = useRouter()
const auth = useAuth()
const saving = ref(false)
const uploading = ref(false)
const error = ref('')
const fileInput = ref<HTMLInputElement | null>(null)
const form = reactive({
  name: '',
  phone: '',
  email: '',
  address: '',
  city: '',
  current_password: '',
  password: '',
  password_confirmation: '',
})

onMounted(async () => {
  if (!getToken()) {
    router.replace({ name: 'auth', query: { redirect: '/compte/modifier' } })
    return
  }
  if (!auth.state.user) await auth.refreshProfile()
  const u = auth.state.user
  form.name = u?.name || ''
  form.phone = u?.phone || ''
  form.email = u?.email || ''
  form.address = u?.address || ''
  form.city = u?.city || ''
})

async function onAvatarChange(e: Event) {
  const input = e.target as HTMLInputElement
  const file = input.files?.[0]
  if (!file) return
  uploading.value = true
  error.value = ''
  try {
    const body = new FormData()
    body.append('avatar', file)
    const headers = new Headers()
    headers.set('Accept', 'application/json')
    headers.set('X-Requested-With', 'XMLHttpRequest')
    const token = getToken()
    if (token) headers.set('Authorization', `Bearer ${token}`)
    const response = await fetch('/api/customer/profile/avatar', {
      method: 'POST',
      headers,
      body,
    })
    const data = await response.json().catch(() => ({}))
    if (!response.ok) {
      throw new Error(data.message || 'Upload échoué')
    }
    await auth.refreshProfile()
  } catch (err: any) {
    error.value = err?.message || 'Impossible d’envoyer la photo'
  } finally {
    uploading.value = false
    if (fileInput.value) fileInput.value.value = ''
  }
}

async function save() {
  error.value = ''
  saving.value = true
  try {
    const payload: Record<string, unknown> = {
      name: form.name,
      phone: form.phone,
      email: form.email || null,
      address: form.address || null,
      city: form.city || null,
    }
    if (form.password) {
      payload.password = form.password
      payload.password_confirmation = form.password_confirmation
      payload.current_password = form.current_password
    }
    await api('/customer/profile', { method: 'PUT', json: payload })
    await auth.refreshProfile()
    router.back()
  } catch (e: any) {
    error.value = e?.message || 'Enregistrement impossible'
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <div class="page kv-container">
    <div class="kv-section-title">
      <h2>Modifier mon profil</h2>
    </div>

    <div class="avatar-block">
      <button class="avatar" type="button" @click="fileInput?.click()" :disabled="uploading">
        <img
          v-if="auth.state.user?.avatar_url"
          :src="resolveMediaUrl(auth.state.user.avatar_url)"
          alt=""
        />
        <span v-else>{{ (auth.state.user?.name || 'K').charAt(0) }}</span>
      </button>
      <input ref="fileInput" type="file" accept="image/*" hidden @change="onAvatarChange" />
      <p>{{ uploading ? 'Envoi de la photo…' : 'Changer la photo de profil' }}</p>
    </div>

    <form class="form" @submit.prevent="save">
      <label>Nom complet<input v-model="form.name" class="kv-input" required /></label>
      <label>Téléphone<input v-model="form.phone" class="kv-input" required /></label>
      <label>Email (optionnel)<input v-model="form.email" type="email" class="kv-input" /></label>
      <label>Adresse<input v-model="form.address" class="kv-input" /></label>
      <label>Ville<input v-model="form.city" class="kv-input" /></label>

      <h3>Mot de passe (optionnel)</h3>
      <label>Mot de passe actuel<input v-model="form.current_password" type="password" class="kv-input" /></label>
      <label>Nouveau mot de passe<input v-model="form.password" type="password" class="kv-input" minlength="6" /></label>
      <label>Confirmer<input v-model="form.password_confirmation" type="password" class="kv-input" /></label>

      <p v-if="error" class="error">{{ error }}</p>
      <button class="kv-btn kv-btn-dark full" type="submit" :disabled="saving">
        {{ saving ? 'Enregistrement…' : 'Enregistrer' }}
      </button>
    </form>
  </div>
</template>

<style scoped>
.page {
  padding: 1.1rem 0 2rem;
}
.avatar-block {
  text-align: center;
  margin-bottom: 1.25rem;
}
.avatar {
  width: 84px;
  height: 84px;
  margin: 0 auto 0.55rem;
  border-radius: 999px;
  overflow: hidden;
  display: grid;
  place-items: center;
  background: linear-gradient(135deg, #3e2723, #251614);
  color: var(--kv-gold-light);
  font-family: var(--kv-font-display);
  font-size: 1.8rem;
  border: 2px solid rgba(197, 160, 128, 0.45);
  cursor: pointer;
  padding: 0;
}
.avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.avatar-block p {
  margin: 0;
  color: var(--kv-gold);
  font-size: 0.78rem;
  font-weight: 700;
}
.form {
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
h3 {
  margin: 0.5rem 0 0;
  font-size: 0.9rem;
}
.error {
  color: #8b3a2f;
  font-size: 0.85rem;
}
.full {
  width: 100%;
}
</style>
