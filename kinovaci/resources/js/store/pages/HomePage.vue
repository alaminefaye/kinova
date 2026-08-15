<script setup lang="ts">
import { computed, onMounted, onBeforeUnmount, ref } from 'vue'
import { useRouter } from 'vue-router'
import ProductCard from '../components/ProductCard.vue'
import UniverseCard from '../components/UniverseCard.vue'
import SoftImage from '../components/SoftImage.vue'
import KinovaLoader from '../components/KinovaLoader.vue'
import { useCatalog } from '../state/catalog'
import { useAuth } from '../state/auth'

const router = useRouter()
const catalog = useCatalog()
const auth = useAuth()
const heroIndex = ref(0)
let timer: ReturnType<typeof setInterval> | null = null

const heroSlides = computed(() => catalog.state.heroSlides)
const categories = computed(() => catalog.state.categories)
const featured = computed(() => catalog.featured.value)
const news = computed(() => catalog.news.value)

function categoryCount(id: string) {
  return catalog.byCategory(id).length
}

function openCategory(id: string) {
  router.push({ name: 'catalog', query: { category: id } })
}

function onHeroCta(slide: { linkType: string; linkValue?: string | null }) {
  if (slide.linkType === 'none') return
  if (slide.linkType === 'category' && slide.linkValue) {
    openCategory(slide.linkValue)
    return
  }
  router.push({ name: 'catalog' })
}

onMounted(() => {
  timer = setInterval(() => {
    if (heroSlides.value.length <= 1) return
    heroIndex.value = (heroIndex.value + 1) % heroSlides.value.length
  }, 5000)
})

onBeforeUnmount(() => {
  if (timer) clearInterval(timer)
})
</script>

<template>
  <div class="home">
    <div class="kv-container">
      <section v-if="heroSlides.length" class="hero">
        <div class="hero-track" :style="{ transform: `translateX(-${heroIndex * 100}%)` }">
          <article v-for="slide in heroSlides" :key="slide.id" class="hero-slide">
            <SoftImage :url="slide.imageUrl" :alt="slide.title" />
            <div class="hero-veil" />
            <div class="hero-copy">
              <span v-if="slide.tag">{{ slide.tag }}</span>
              <h2 class="kv-display">{{ slide.title }}</h2>
              <button class="kv-btn kv-btn-primary" type="button" @click="onHeroCta(slide)">
                {{ slide.ctaLabel || 'DÉCOUVRIR' }}
              </button>
            </div>
          </article>
        </div>
        <div class="dots">
          <button
            v-for="(s, i) in heroSlides"
            :key="s.id"
            type="button"
            :class="{ on: i === heroIndex }"
            @click="heroIndex = i"
          />
        </div>
      </section>

      <div class="promo">LIVRAISON OFFERTE DÈS 50 000 FCFA · RETOURS 14 JOURS</div>

      <!-- Bannière Cercle VIP si non connecté -->
      <div v-if="!auth.isLoggedIn.value" class="vip-banner" @click="router.push({ name: 'auth' })">
        <div class="vip-icon">
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
          </svg>
        </div>
        <div class="vip-content">
          <h3>Rejoignez le Cercle VIP</h3>
          <p>10 000 FCFA dépensés = 1 point. Avantages exclusifs.</p>
        </div>
        <span class="vip-arrow">›</span>
      </div>

      <!-- Engagements KINOVA -->
      <div class="perks-row">
        <div class="perk-card">
          <div class="perk-icon">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
              <rect x="1" y="3" width="15" height="13"></rect>
              <polygon points="16 8 20 8 23 11 23 16 16 16 16 8"></polygon>
              <circle cx="5.5" cy="18.5" r="2.5"></circle>
              <circle cx="18.5" cy="18.5" r="2.5"></circle>
            </svg>
          </div>
          <div class="perk-text">
            <strong>Livraison Offerte</strong>
            <span>Dès 50 000 FCFA d’achat</span>
          </div>
        </div>
        <div class="perk-card">
          <div class="perk-icon">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
              <path d="M12 2a9 9 0 0 1 9 9c0 4.97-4.03 9-9 9A9 9 0 0 1 3 11c0-4.97 4.03-9 9-9z"></path>
              <path d="M12 6v6l4 2"></path>
            </svg>
          </div>
          <div class="perk-text">
            <strong>Soins Naturels</strong>
            <span>Formules pures</span>
          </div>
        </div>
        <div class="perk-card">
          <div class="perk-icon">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
              <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path>
              <polyline points="9 12 11 14 15 10"></polyline>
            </svg>
          </div>
          <div class="perk-text">
            <strong>Garantie KINOVA</strong>
            <span>Satisfait ou remboursé</span>
          </div>
        </div>
      </div>

      <section class="block">
        <div class="kv-section-title">
          <h2>Nos Univers</h2>
          <RouterLink :to="{ name: 'catalog' }">Tout voir ›</RouterLink>
        </div>
        <div class="univers-row">
          <UniverseCard
            v-for="cat in categories"
            :key="cat.id"
            :name="cat.name"
            :image-url="cat.imageUrl"
            :count="categoryCount(cat.id)"
            @click="openCategory(cat.id)"
          />
        </div>
      </section>

      <section v-if="featured.length" class="block">
        <div class="kv-section-title">
          <h2>Sélection</h2>
          <RouterLink :to="{ name: 'catalog' }">Voir tout ›</RouterLink>
        </div>
        <div class="kv-grid-products">
          <ProductCard v-for="p in featured.slice(0, 8)" :key="p.id" :product="p" />
        </div>
      </section>

      <section v-if="news.length" class="block">
        <div class="kv-section-title">
          <h2>Nouveautés</h2>
          <RouterLink :to="{ name: 'catalog' }">Voir tout ›</RouterLink>
        </div>
        <div class="kv-grid-products">
          <ProductCard v-for="p in news.slice(0, 8)" :key="p.id" :product="p" />
        </div>
      </section>

      <KinovaLoader
        v-if="catalog.state.loading && !catalog.state.loaded"
        compact
        message="Chargement du catalogue"
        :size="64"
      />
      <p v-else-if="catalog.state.error" class="status error">{{ catalog.state.error }}</p>
    </div>
  </div>
</template>

<style scoped>
.home {
  padding: 1rem 0 2rem;
}
.hero {
  position: relative;
  overflow: hidden;
  border-radius: 22px;
  height: min(52vw, 300px);
  min-height: 230px;
  box-shadow: 0 10px 28px rgba(62, 39, 35, 0.22);
  margin-bottom: 0.85rem;
  background: #1b110b;
}
.hero-track {
  display: flex;
  height: 100%;
  width: 100%;
  transition: transform 0.7s cubic-bezier(0.22, 1, 0.36, 1);
  will-change: transform;
}
.hero-slide {
  position: relative;
  flex: 0 0 100%;
  width: 100%;
  height: 100%;
  overflow: hidden;
}
.hero-slide :deep(.soft-img) {
  object-fit: cover;
  object-position: center;
  transform: scale(1.02);
}
.hero-veil {
  position: absolute;
  inset: 0;
  background: linear-gradient(
    115deg,
    rgba(27, 17, 11, 0.82) 0%,
    rgba(27, 17, 11, 0.35) 48%,
    rgba(27, 17, 11, 0.08) 100%
  );
  pointer-events: none;
}
.hero-copy {
  position: absolute;
  left: 1.1rem;
  bottom: 1.15rem;
  right: 3.5rem;
  color: var(--kv-cream);
  z-index: 1;
}
.hero-copy span {
  display: inline-block;
  font-size: 0.62rem;
  font-weight: 800;
  letter-spacing: 0.14em;
  color: var(--kv-gold-light);
  margin-bottom: 0.4rem;
  padding: 0.22rem 0.55rem;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.12);
  border: 1px solid rgba(197, 160, 128, 0.45);
}
.hero-copy h2 {
  margin: 0 0 0.75rem;
  font-size: clamp(1.2rem, 4vw, 1.75rem);
  max-width: 15ch;
  line-height: 1.15;
  white-space: pre-line;
  text-shadow: 0 2px 16px rgba(0, 0, 0, 0.35);
}
.dots {
  position: absolute;
  right: 1rem;
  bottom: 1.1rem;
  display: flex;
  gap: 0.35rem;
  z-index: 2;
}
.dots button {
  width: 7px;
  height: 7px;
  border-radius: 999px;
  border: none;
  background: rgba(253, 251, 247, 0.35);
  cursor: pointer;
  padding: 0;
  transition: width 0.25s ease, background 0.25s ease;
}
.dots button.on {
  width: 18px;
  background: var(--kv-gold);
}
.promo {
  background: linear-gradient(90deg, #d4af37, #c5a080, #e8d5b7);
  color: var(--kv-brown);
  text-align: center;
  font-size: 0.68rem;
  font-weight: 800;
  letter-spacing: 0.08em;
  padding: 0.55rem 0.75rem;
  border-radius: 12px;
  margin-bottom: 0.85rem;
}
/* Bannière VIP */
.vip-banner {
  background: linear-gradient(135deg, #2b1b14 0%, #1a0f0a 100%);
  border: 1px solid rgba(197, 160, 128, 0.4);
  border-radius: 18px;
  padding: 0.95rem 1.15rem;
  display: flex;
  align-items: center;
  gap: 0.95rem;
  margin-bottom: 0.85rem;
  cursor: pointer;
  box-shadow: 0 8px 22px rgba(43, 27, 20, 0.25);
  transition: transform 0.2s ease, border-color 0.2s ease;
}
.vip-banner:hover {
  transform: translateY(-2px);
  border-color: rgba(212, 175, 55, 0.7);
}
.vip-icon {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: rgba(212, 175, 55, 0.15);
  border: 1px solid rgba(212, 175, 55, 0.4);
  display: flex;
  align-items: center;
  justify-content: center;
  color: #f7e7ce;
  flex-shrink: 0;
}
.vip-content {
  flex: 1;
}
.vip-content h3 {
  font-family: var(--kv-font-display, serif);
  font-size: 0.98rem;
  color: #f7e7ce;
  margin: 0 0 2px;
  font-weight: 700;
}
.vip-content p {
  margin: 0;
  font-size: 0.72rem;
  color: var(--kv-sand, #d4a373);
}
.vip-arrow {
  color: var(--kv-gold, #d4af37);
  font-size: 1.25rem;
  font-weight: 700;
}
/* Perks Row */
.perks-row {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 0.65rem;
  background: var(--kv-surface);
  border: 1px solid rgba(197, 160, 128, 0.2);
  border-radius: 16px;
  padding: 0.85rem 0.75rem;
  margin-bottom: 1.35rem;
}
.perk-card {
  display: flex;
  align-items: center;
  gap: 0.55rem;
}
.perk-icon {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background: rgba(197, 160, 128, 0.12);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--kv-brown);
  flex-shrink: 0;
}
.perk-text {
  display: flex;
  flex-direction: column;
}
.perk-text strong {
  font-size: 0.72rem;
  color: var(--kv-brown);
  font-weight: 700;
  line-height: 1.2;
}
.perk-text span {
  font-size: 0.62rem;
  color: var(--kv-muted);
  line-height: 1.2;
}
@media (max-width: 600px) {
  .perks-row {
    grid-template-columns: 1fr;
    gap: 0.65rem;
  }
}
.block {
  margin-bottom: 1.75rem;
}
.univers-row {
  display: flex;
  gap: 0.85rem;
  overflow-x: auto;
  padding-bottom: 0.35rem;
  scrollbar-width: none;
}
.univers-row::-webkit-scrollbar {
  display: none;
}
.status {
  text-align: center;
  color: var(--kv-muted);
  font-size: 0.9rem;
}
.status.error {
  color: #8b3a2f;
}
</style>
