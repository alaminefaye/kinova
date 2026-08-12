<script setup lang="ts">
import { computed, onMounted, onBeforeUnmount, ref } from 'vue'
import { useRouter } from 'vue-router'
import ProductCard from '../components/ProductCard.vue'
import UniverseCard from '../components/UniverseCard.vue'
import SoftImage from '../components/SoftImage.vue'
import KinovaLoader from '../components/KinovaLoader.vue'
import { useCatalog } from '../state/catalog'

const router = useRouter()
const catalog = useCatalog()
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

      <div class="promo">LIVRAISON OFFERTE DÈS 100 FCFA · RETOURS 14 JOURS</div>

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
  margin-bottom: 1.35rem;
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
