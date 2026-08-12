<script setup lang="ts">
import { computed, onMounted, onBeforeUnmount, ref } from 'vue'
import { useRouter } from 'vue-router'
import ProductCard from '../components/ProductCard.vue'
import UniverseCard from '../components/UniverseCard.vue'
import SoftImage from '../components/SoftImage.vue'
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

      <p v-if="catalog.state.loading" class="status">Chargement du catalogue…</p>
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
  height: min(52vw, 280px);
  min-height: 220px;
  box-shadow: var(--kv-shadow);
  margin-bottom: 0.85rem;
}
.hero-track {
  display: flex;
  height: 100%;
  transition: transform 0.65s cubic-bezier(0.4, 0, 0.2, 1);
}
.hero-slide {
  position: relative;
  min-width: 100%;
  height: 100%;
}
.hero-veil {
  position: absolute;
  inset: 0;
  background: linear-gradient(120deg, rgba(27, 17, 11, 0.72), rgba(27, 17, 11, 0.15) 55%, transparent);
}
.hero-copy {
  position: absolute;
  left: 1.1rem;
  bottom: 1.1rem;
  right: 1.1rem;
  color: var(--kv-cream);
}
.hero-copy span {
  display: inline-block;
  font-size: 0.65rem;
  font-weight: 800;
  letter-spacing: 0.14em;
  color: var(--kv-gold);
  margin-bottom: 0.35rem;
}
.hero-copy h2 {
  margin: 0 0 0.75rem;
  font-size: clamp(1.2rem, 4vw, 1.75rem);
  max-width: 14ch;
  line-height: 1.15;
}
.dots {
  position: absolute;
  right: 1rem;
  bottom: 1rem;
  display: flex;
  gap: 0.35rem;
}
.dots button {
  width: 7px;
  height: 7px;
  border-radius: 999px;
  border: none;
  background: rgba(253, 251, 247, 0.35);
  cursor: pointer;
  padding: 0;
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
