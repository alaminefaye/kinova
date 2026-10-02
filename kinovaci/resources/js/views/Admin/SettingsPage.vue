<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { api } from '@/api/client'

type Settings = Record<string, any>

const loading = ref(true)
const saving = ref(false)
const error = ref('')
const success = ref('')
const form = reactive<Settings>({})
const defaults = ref<Settings>({})

const sections = [
  { key: 'section_hero', label: 'Slider accueil', hint: 'Grandes images en haut' },
  { key: 'section_promo_banner', label: 'Bandeau doré', hint: 'Ex. « Livraison offerte dès… »' },
  { key: 'section_categories', label: 'Nos Univers', hint: 'Catégories' },
  { key: 'section_featured', label: 'Sélection Premium', hint: 'Produits mis en avant' },
  { key: 'section_vip_banner', label: 'Bannière Cercle VIP', hint: 'Visible seulement si non connecté' },
  { key: 'section_perks', label: 'Engagements', hint: 'Les 3 garanties' },
  { key: 'section_news', label: 'Nouveautés', hint: 'Grille des nouveautés' },
]

const profileToggles = [
  { key: 'profile_show_loyalty', label: 'Points de fidélité', hint: 'Titre, solde de points et règle' },
  { key: 'profile_show_tier_badge', label: 'Badge du palier', hint: 'STANDARD / ARGENT / OR / VIP' },
  { key: 'profile_show_next_tier', label: 'Prochain palier', hint: '« Plus que X points pour… »' },
]

const profileFields = [
  { key: 'profile_loyalty_title', label: 'Titre du bloc' },
  { key: 'profile_loyalty_rule', label: 'Règle affichée sous les points' },
]

function formatMoney(value: number) {
  return `${Number(value || 0).toLocaleString('fr-FR').replace(/\u202f|\u00a0/g, ' ')} FCFA`
}

function render(text: string) {
  const pts = Number(form.loyalty_points_per_step || 0)
  return (text || '')
    .replaceAll('{seuil}', formatMoney(form.free_shipping_threshold))
    .replaceAll('{frais}', formatMoney(form.shipping_fee))
    .replaceAll('{montant}', formatMoney(form.loyalty_amount_per_step))
    .replaceAll('{points}', `${pts} point${pts > 1 ? 's' : ''}`)
}

const shippingSummary = computed(() => {
  if (!form.free_shipping_enabled) {
    return `Livraison toujours facturée ${formatMoney(form.shipping_fee)}.`
  }
  return `Livraison ${formatMoney(form.shipping_fee)}, offerte dès ${formatMoney(form.free_shipping_threshold)} d’achat.`
})

const loyaltySummary = computed(() => {
  const step = Number(form.loyalty_amount_per_step || 0)
  const pts = Number(form.loyalty_points_per_step || 0)
  const example = step > 0 ? Math.floor(100000 / step) * pts : 0
  return `${formatMoney(step)} dépensés = ${pts} point${pts > 1 ? 's' : ''}. Exemple : une commande de 100 000 FCFA rapporte ${example} point${example > 1 ? 's' : ''}.`
})

async function load() {
  loading.value = true
  error.value = ''
  try {
    const res = await api<any>('/admin/settings')
    Object.assign(form, res.data || {})
    defaults.value = res.defaults || {}
  } catch (e: any) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

async function save() {
  saving.value = true
  error.value = ''
  success.value = ''
  try {
    const res = await api<any>('/admin/settings', { method: 'PUT', json: { ...form } })
    Object.assign(form, res.data || {})
    success.value = res.message || 'Paramètres enregistrés.'
    setTimeout(() => (success.value = ''), 3000)
  } catch (e: any) {
    error.value = e.message
  } finally {
    saving.value = false
  }
}

function resetText(key: string) {
  form[key] = defaults.value[key] ?? ''
}

onMounted(load)
</script>

<template>
  <AdminLayout>
    <div class="space-y-6 pb-24">
      <div class="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 class="text-2xl font-semibold text-gray-800 dark:text-white">Paramètres boutique</h1>
          <p class="text-sm text-gray-500 mt-1">
            Livraison, fidélité VIP et contenu de la page d’accueil (app mobile + boutique web)
          </p>
        </div>
        <button
          class="rounded-lg bg-brand-500 px-5 py-2.5 text-sm font-medium text-white hover:bg-brand-600 disabled:opacity-50"
          :disabled="saving || loading"
          @click="save"
        >
          {{ saving ? 'Enregistrement…' : 'Enregistrer' }}
        </button>
      </div>

      <div v-if="error" class="rounded-lg border border-error-200 bg-error-50 px-4 py-3 text-error-700">{{ error }}</div>
      <div v-if="success" class="rounded-lg border border-success-200 bg-success-50 px-4 py-3 text-success-700">{{ success }}</div>

      <div v-if="loading" class="text-gray-500">Chargement…</div>

      <template v-else>
        <!-- Livraison -->
        <section class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03] space-y-4">
          <div>
            <h2 class="text-lg font-semibold text-gray-800 dark:text-white">Livraison</h2>
            <p class="text-sm text-gray-500">{{ shippingSummary }}</p>
          </div>
          <div class="grid gap-4 md:grid-cols-3">
            <label class="text-sm">
              <span class="text-gray-500 block mb-1">Frais de livraison (FCFA)</span>
              <input v-model.number="form.shipping_fee" type="number" min="0" class="w-full rounded-lg border border-gray-200 px-3 py-2.5 dark:border-gray-700 dark:bg-gray-900 dark:text-white" />
            </label>
            <label class="text-sm">
              <span class="text-gray-500 block mb-1">Livraison offerte dès (FCFA)</span>
              <input v-model.number="form.free_shipping_threshold" type="number" min="0" :disabled="!form.free_shipping_enabled" class="w-full rounded-lg border border-gray-200 px-3 py-2.5 disabled:opacity-50 dark:border-gray-700 dark:bg-gray-900 dark:text-white" />
            </label>
            <label class="text-sm flex items-center gap-3 md:pt-6">
              <input v-model="form.free_shipping_enabled" type="checkbox" class="h-5 w-5 accent-brand-500" />
              <span class="text-gray-700 dark:text-gray-300">Activer la livraison offerte</span>
            </label>
          </div>
        </section>

        <!-- Fidélité -->
        <section class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03] space-y-4">
          <div>
            <h2 class="text-lg font-semibold text-gray-800 dark:text-white">Cercle VIP / Fidélité</h2>
            <p class="text-sm text-gray-500">{{ loyaltySummary }}</p>
          </div>
          <div class="grid gap-4 md:grid-cols-2">
            <label class="text-sm">
              <span class="text-gray-500 block mb-1">Montant dépensé (FCFA)</span>
              <input v-model.number="form.loyalty_amount_per_step" type="number" min="1" class="w-full rounded-lg border border-gray-200 px-3 py-2.5 dark:border-gray-700 dark:bg-gray-900 dark:text-white" />
            </label>
            <label class="text-sm">
              <span class="text-gray-500 block mb-1">Points gagnés pour ce montant</span>
              <input v-model.number="form.loyalty_points_per_step" type="number" min="0" class="w-full rounded-lg border border-gray-200 px-3 py-2.5 dark:border-gray-700 dark:bg-gray-900 dark:text-white" />
            </label>
          </div>
          <div>
            <p class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Paliers (points nécessaires)</p>
            <div class="grid gap-4 md:grid-cols-3">
              <label class="text-sm">
                <span class="text-gray-500 block mb-1">Silver</span>
                <input v-model.number="form.tier_silver_points" type="number" min="0" class="w-full rounded-lg border border-gray-200 px-3 py-2.5 dark:border-gray-700 dark:bg-gray-900 dark:text-white" />
              </label>
              <label class="text-sm">
                <span class="text-gray-500 block mb-1">Gold</span>
                <input v-model.number="form.tier_gold_points" type="number" min="0" class="w-full rounded-lg border border-gray-200 px-3 py-2.5 dark:border-gray-700 dark:bg-gray-900 dark:text-white" />
              </label>
              <label class="text-sm">
                <span class="text-gray-500 block mb-1">VIP</span>
                <input v-model.number="form.tier_vip_points" type="number" min="0" class="w-full rounded-lg border border-gray-200 px-3 py-2.5 dark:border-gray-700 dark:bg-gray-900 dark:text-white" />
              </label>
            </div>
          </div>
        </section>

        <!-- Profil client -->
        <section class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03] space-y-4">
          <div>
            <h2 class="text-lg font-semibold text-gray-800 dark:text-white">Profil client — carte fidélité</h2>
            <p class="text-sm text-gray-500">Bloc « Fidélité KINOVA » affiché dans l’onglet Compte.</p>
          </div>
          <div class="grid gap-3 md:grid-cols-3">
            <label
              v-for="s in profileToggles"
              :key="s.key"
              class="flex items-center justify-between gap-3 rounded-xl border border-gray-100 px-4 py-3 cursor-pointer dark:border-gray-800"
            >
              <span>
                <span class="block text-sm font-medium text-gray-800 dark:text-white">{{ s.label }}</span>
                <span class="block text-xs text-gray-500">{{ s.hint }}</span>
              </span>
              <span class="flex items-center gap-2">
                <span class="text-xs" :class="form[s.key] ? 'text-success-600' : 'text-gray-400'">
                  {{ form[s.key] ? 'Affiché' : 'Masqué' }}
                </span>
                <input v-model="form[s.key]" type="checkbox" class="h-5 w-5 accent-brand-500" />
              </span>
            </label>
          </div>
          <div class="grid gap-4 md:grid-cols-2">
            <div v-for="field in profileFields" :key="field.key" class="text-sm">
              <div class="flex items-center justify-between mb-1">
                <span class="text-gray-500">{{ field.label }}</span>
                <button type="button" class="text-xs text-gray-400 hover:text-brand-500" @click="resetText(field.key)">Par défaut</button>
              </div>
              <input
                v-model="form[field.key]"
                :disabled="!form.profile_show_loyalty"
                class="w-full rounded-lg border border-gray-200 px-3 py-2.5 disabled:opacity-50 dark:border-gray-700 dark:bg-gray-900 dark:text-white"
              />
              <p class="mt-1 text-xs text-gray-400">Aperçu : {{ render(form[field.key]) || '(vide = non affiché)' }}</p>
            </div>
          </div>
        </section>

        <!-- Sections accueil -->
        <section class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03] space-y-4">
          <div>
            <h2 class="text-lg font-semibold text-gray-800 dark:text-white">Sections de l’accueil</h2>
            <p class="text-sm text-gray-500">Afficher ou masquer chaque bloc de la page d’accueil.</p>
          </div>
          <div class="grid gap-3 md:grid-cols-2">
            <label
              v-for="s in sections"
              :key="s.key"
              class="flex items-center justify-between gap-3 rounded-xl border border-gray-100 px-4 py-3 cursor-pointer dark:border-gray-800"
            >
              <span>
                <span class="block text-sm font-medium text-gray-800 dark:text-white">{{ s.label }}</span>
                <span class="block text-xs text-gray-500">{{ s.hint }}</span>
              </span>
              <span class="flex items-center gap-2">
                <span class="text-xs" :class="form[s.key] ? 'text-success-600' : 'text-gray-400'">
                  {{ form[s.key] ? 'Affichée' : 'Masquée' }}
                </span>
                <input v-model="form[s.key]" type="checkbox" class="h-5 w-5 accent-brand-500" />
              </span>
            </label>
          </div>
        </section>

        <!-- Textes -->
        <section class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03] space-y-5">
          <div>
            <h2 class="text-lg font-semibold text-gray-800 dark:text-white">Textes de l’accueil</h2>
            <p class="text-sm text-gray-500">
              Variables automatiques :
              <code class="text-brand-500">{seuil}</code> livraison offerte,
              <code class="text-brand-500">{frais}</code> frais de livraison,
              <code class="text-brand-500">{montant}</code> montant fidélité,
              <code class="text-brand-500">{points}</code> points gagnés.
            </p>
          </div>

          <div
            v-for="field in [
              { key: 'promo_banner_text', label: 'Bandeau doré' },
              { key: 'vip_title', label: 'Titre Cercle VIP' },
              { key: 'vip_subtitle', label: 'Sous-titre Cercle VIP' },
              { key: 'categories_title', label: 'Titre « Nos Univers »' },
              { key: 'featured_title', label: 'Titre « Sélection Premium »' },
              { key: 'news_title', label: 'Titre « Nouveautés »' },
            ]"
            :key="field.key"
            class="text-sm"
          >
            <div class="flex items-center justify-between mb-1">
              <span class="text-gray-500">{{ field.label }}</span>
              <button type="button" class="text-xs text-gray-400 hover:text-brand-500" @click="resetText(field.key)">Par défaut</button>
            </div>
            <input v-model="form[field.key]" class="w-full rounded-lg border border-gray-200 px-3 py-2.5 dark:border-gray-700 dark:bg-gray-900 dark:text-white" />
            <p class="mt-1 text-xs text-gray-400">Aperçu : {{ render(form[field.key]) }}</p>
          </div>

          <div>
            <p class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Engagements (3 garanties)</p>
            <div class="grid gap-4 md:grid-cols-3">
              <div v-for="n in [1, 2, 3]" :key="n" class="rounded-xl border border-gray-100 p-3 space-y-2 dark:border-gray-800">
                <input v-model="form[`perk${n}_title`]" placeholder="Titre" class="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white" />
                <input v-model="form[`perk${n}_subtitle`]" placeholder="Sous-titre" class="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white" />
                <p class="text-xs text-gray-400">
                  Aperçu : <strong>{{ render(form[`perk${n}_title`]) }}</strong> — {{ render(form[`perk${n}_subtitle`]) }}
                </p>
              </div>
            </div>
          </div>
        </section>

        <div class="flex justify-end">
          <button
            class="rounded-lg bg-brand-500 px-5 py-2.5 text-sm font-medium text-white hover:bg-brand-600 disabled:opacity-50"
            :disabled="saving"
            @click="save"
          >
            {{ saving ? 'Enregistrement…' : 'Enregistrer' }}
          </button>
        </div>
      </template>
    </div>
  </AdminLayout>
</template>
