<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, reactive, ref } from 'vue'
import { RouterLink } from 'vue-router'
import VueApexCharts from 'vue3-apexcharts/core'
import 'apexcharts/area'
import 'apexcharts/bar'
import 'apexcharts/donut'
import 'apexcharts/features/legend'
import type { ApexOptions } from 'apexcharts'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { useTheme } from '@/components/layout/ThemeProvider.vue'
import { api } from '@/api/client'
import { session } from '@/api/session'

type DayPoint = { date: string; label: string; amount: number; count: number }
type CumulativePoint = { date: string; label: string; total: number }
type MonthPoint = { month: string; label: string; amount: number; count: number }
type TopProduct = { name: string; quantity: number; revenue: number }
type CategoryRevenue = { name: string; revenue: number }

const loading = ref(true)
const refreshing = ref(false)
const error = ref('')
const period = ref<7 | 30>(30)
const { isDarkMode } = useTheme()

const stats = reactive({
  today_revenue: 0,
  today_sales_count: 0,
  today_orders_count: 0,
  yesterday_revenue: 0,
  month_revenue: 0,
  month_sales_count: 0,
  last_month_revenue: 0,
  total_revenue: 0,
  total_sales_count: 0,
  average_basket: 0,
  first_sale_date: null as string | null,
  orders_count: 0,
  pending_orders: 0,
  processing_orders: 0,
  delivered_orders: 0,
  cancelled_orders: 0,
  orders_by_status: {} as Record<string, number>,
  total_customers: 0,
  new_customers_today: 0,
  products_count: 0,
  categories_count: 0,
  sales_last_30_days: [] as DayPoint[],
  sales_since_start: [] as CumulativePoint[],
  sales_by_month: [] as MonthPoint[],
  top_products: [] as TopProduct[],
  revenue_by_category: [] as CategoryRevenue[],
  latest_orders: [] as any[],
  low_stock: [] as any[],
})

async function load(silent = false) {
  if (silent) refreshing.value = true
  else loading.value = true
  error.value = ''
  try {
    const res = await api<{ data: Partial<typeof stats> }>('/admin/dashboard')
    Object.assign(stats, res.data)
  } catch (e: any) {
    error.value = e.message || 'Erreur'
  } finally {
    loading.value = false
    refreshing.value = false
  }
}

let timer: ReturnType<typeof setInterval> | undefined
onMounted(() => {
  load()
  timer = setInterval(() => {
    if (document.visibilityState === 'visible') load(true)
  }, 120_000)
})
onBeforeUnmount(() => clearInterval(timer))

/* ---------- Formatage ---------- */

const moneyFormat = new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'XOF', maximumFractionDigits: 0 })
const compactFormat = new Intl.NumberFormat('fr-FR', { notation: 'compact', maximumFractionDigits: 1 })
const money = (v: number) => moneyFormat.format(Number(v) || 0)
const compact = (v: number) => compactFormat.format(Number(v) || 0)
const plural = (n: number, word: string) => `${n} ${word}${n > 1 ? 's' : ''}`

const greeting = computed(() => {
  const hour = new Date().getHours()
  const name = session.user?.name?.split(' ')[0] ?? ''
  return `${hour < 18 ? 'Bonjour' : 'Bonsoir'}${name ? ' ' + name : ''}`
})

const todayLabel = computed(() => {
  const label = new Intl.DateTimeFormat('fr-FR', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' }).format(new Date())
  return label.charAt(0).toUpperCase() + label.slice(1)
})

const sinceLabel = computed(() => {
  if (!stats.first_sale_date) return 'Aucune vente encaissée pour le moment'
  const date = new Date(`${stats.first_sale_date}T00:00:00`)
  return `Depuis le ${new Intl.DateTimeFormat('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' }).format(date)}`
})

const todayTrend = computed(() => {
  const today = stats.today_revenue
  const yesterday = stats.yesterday_revenue
  if (!yesterday) return today > 0 ? { text: 'Hier : 0 F', up: true } : null
  const pct = Math.round(((today - yesterday) / yesterday) * 100)
  return { text: `${pct >= 0 ? '+' : ''}${pct} % vs hier`, up: pct >= 0 }
})

const statusMeta: Record<string, { label: string; color: string; badge: string }> = {
  pending: { label: 'En attente', color: '#f79009', badge: 'bg-warning-50 text-warning-700 dark:bg-warning-500/15 dark:text-warning-400' },
  processing: { label: 'Confirmée', color: '#0ba5ec', badge: 'bg-blue-light-50 text-blue-light-700 dark:bg-blue-light-500/15 dark:text-blue-light-400' },
  shipped: { label: 'Expédiée', color: '#7a5af8', badge: 'bg-theme-purple-500/10 text-theme-purple-500' },
  delivered: { label: 'Livrée', color: '#12b76a', badge: 'bg-success-50 text-success-700 dark:bg-success-500/15 dark:text-success-400' },
  cancelled: { label: 'Annulée', color: '#f04438', badge: 'bg-error-50 text-error-700 dark:bg-error-500/15 dark:text-error-400' },
}
const statusKeys = Object.keys(statusMeta)

/* ---------- Graphiques ---------- */

const primary = computed(() => (isDarkMode.value ? '#d6b48f' : '#3e2723'))
const palette = computed(() => [primary.value, '#b08968', '#ddb892', '#7f5539', '#e6ccb2', '#9c6644', '#c9ada7'])

const baseOptions = computed<ApexOptions>(() => ({
  chart: { fontFamily: 'Outfit, sans-serif', toolbar: { show: false }, zoom: { enabled: false }, background: 'transparent' },
  dataLabels: { enabled: false },
  grid: { borderColor: isDarkMode.value ? '#1d2939' : '#eaecf0', strokeDashArray: 4, yaxis: { lines: { show: true } } },
  tooltip: { theme: isDarkMode.value ? 'dark' : 'light' },
  legend: { show: false },
}))

const recentDays = computed(() => stats.sales_last_30_days.slice(-period.value))
const periodTotal = computed(() => recentDays.value.reduce((sum, d) => sum + d.amount, 0))

const revenueChart = computed(() => ({
  series: [{ name: 'Recettes', data: recentDays.value.map((d) => d.amount) }],
  options: {
    ...baseOptions.value,
    colors: [primary.value],
    stroke: { curve: 'smooth', width: 3 },
    fill: { type: 'gradient', gradient: { shadeIntensity: 1, opacityFrom: 0.35, opacityTo: 0.02, stops: [0, 95, 100] } },
    markers: { size: 0, hover: { size: 5 } },
    xaxis: {
      categories: recentDays.value.map((d) => d.label),
      tickAmount: period.value === 30 ? 10 : undefined,
      labels: { rotate: 0, hideOverlappingLabels: true },
      axisBorder: { show: false },
      axisTicks: { show: false },
    },
    yaxis: { labels: { formatter: (v: number) => compact(v) } },
    tooltip: {
      ...baseOptions.value.tooltip,
      y: { formatter: (v: number, opts?: any) => `${money(v)} · ${plural(recentDays.value[opts?.dataPointIndex]?.count ?? 0, 'vente')}` },
    },
  } as ApexOptions,
}))

const cumulativeChart = computed(() => ({
  series: [{ name: 'Gains cumulés', data: stats.sales_since_start.map((d) => d.total) }],
  options: {
    ...baseOptions.value,
    colors: ['#b08968'],
    stroke: { curve: 'smooth', width: 3 },
    fill: { type: 'gradient', gradient: { shadeIntensity: 1, opacityFrom: 0.4, opacityTo: 0.05, stops: [0, 100] } },
    xaxis: {
      categories: stats.sales_since_start.map((d) => d.label),
      tickAmount: Math.min(6, Math.max(1, stats.sales_since_start.length - 1)),
      labels: { rotate: 0, hideOverlappingLabels: true },
      axisBorder: { show: false },
      axisTicks: { show: false },
    },
    yaxis: { labels: { formatter: (v: number) => compact(v) } },
    tooltip: { ...baseOptions.value.tooltip, y: { formatter: (v: number) => money(v) } },
  } as ApexOptions,
}))

const monthlyChart = computed(() => ({
  series: [{ name: 'Recettes', data: stats.sales_by_month.map((m) => m.amount) }],
  options: {
    ...baseOptions.value,
    colors: [primary.value],
    plotOptions: { bar: { borderRadius: 6, borderRadiusApplication: 'end', columnWidth: '45%' } },
    xaxis: { categories: stats.sales_by_month.map((m) => m.label), axisBorder: { show: false }, axisTicks: { show: false } },
    yaxis: { labels: { formatter: (v: number) => compact(v) } },
    tooltip: {
      ...baseOptions.value.tooltip,
      y: { formatter: (v: number, opts?: any) => `${money(v)} · ${plural(stats.sales_by_month[opts?.dataPointIndex]?.count ?? 0, 'vente')}` },
    },
  } as ApexOptions,
}))

function donutOptions(labels: string[], colors: string[], totalLabel: string, totalFormatter: () => string): ApexOptions {
  return {
    ...baseOptions.value,
    labels,
    colors,
    stroke: { width: 2, colors: [isDarkMode.value ? '#101828' : '#ffffff'] },
    legend: { show: true, position: 'bottom', fontSize: '13px', markers: { size: 6 }, itemMargin: { horizontal: 8, vertical: 4 } },
    plotOptions: {
      pie: {
        donut: {
          size: '72%',
          labels: {
            show: true,
            value: { fontSize: '22px', fontWeight: 600, color: isDarkMode.value ? '#ffffff' : '#1d2939' },
            total: { show: true, label: totalLabel, fontSize: '13px', color: '#98a2b3', formatter: totalFormatter },
          },
        },
      },
    },
  }
}

const statusChart = computed(() => {
  const keys = statusKeys.filter((k) => (stats.orders_by_status[k] ?? 0) > 0)
  return {
    series: keys.map((k) => stats.orders_by_status[k] ?? 0),
    options: {
      ...donutOptions(
        keys.map((k) => statusMeta[k].label),
        keys.map((k) => statusMeta[k].color),
        'Commandes',
        () => String(stats.orders_count),
      ),
      tooltip: { ...baseOptions.value.tooltip, y: { formatter: (v: number) => plural(v, 'commande') } },
    } as ApexOptions,
  }
})

const categoryChart = computed(() => ({
  series: stats.revenue_by_category.map((c) => c.revenue),
  options: {
    ...donutOptions(
      stats.revenue_by_category.map((c) => c.name),
      palette.value,
      'Total',
      () => compact(stats.revenue_by_category.reduce((sum, c) => sum + c.revenue, 0)),
    ),
    plotOptions: {
      pie: {
        donut: {
          size: '72%',
          labels: {
            show: true,
            value: { fontSize: '20px', fontWeight: 600, color: isDarkMode.value ? '#ffffff' : '#1d2939', formatter: (v: string) => compact(Number(v)) },
            total: {
              show: true,
              label: 'Total',
              fontSize: '13px',
              color: '#98a2b3',
              formatter: () => compact(stats.revenue_by_category.reduce((sum, c) => sum + c.revenue, 0)),
            },
          },
        },
      },
    },
    tooltip: { ...baseOptions.value.tooltip, y: { formatter: (v: number) => money(v) } },
  } as ApexOptions,
}))

const topMax = computed(() => Math.max(1, ...stats.top_products.map((p) => p.quantity)))

const miniStats = computed(() => [
  { label: "Commandes aujourd'hui", value: stats.today_orders_count, to: '/orders' },
  { label: 'En attente', value: stats.pending_orders, to: '/orders', accent: stats.pending_orders > 0 },
  { label: 'En cours de livraison', value: stats.processing_orders, to: '/orders' },
  { label: 'Livrées', value: stats.delivered_orders, to: '/orders' },
  { label: 'Clients', value: stats.total_customers, hint: stats.new_customers_today ? `+${stats.new_customers_today} aujourd'hui` : '', to: '/users' },
  { label: 'Produits', value: stats.products_count, hint: plural(stats.categories_count, 'catégorie'), to: '/products' },
])

const formatDate = (iso: string) =>
  new Intl.DateTimeFormat('fr-FR', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' }).format(new Date(iso))

const card = 'rounded-2xl border border-gray-200 bg-white p-5 shadow-theme-xs dark:border-gray-800 dark:bg-white/[0.03]'
</script>

<template>
  <AdminLayout>
    <div class="space-y-6">
      <!-- En-tête -->
      <div class="flex flex-wrap items-end justify-between gap-3">
        <div>
          <p class="text-sm text-gray-500 dark:text-gray-400">{{ todayLabel }}</p>
          <h1 class="mt-1 text-2xl font-semibold text-gray-800 dark:text-white">{{ greeting }} 👋</h1>
        </div>
        <button
          type="button"
          class="inline-flex items-center gap-2 rounded-lg border border-gray-200 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 disabled:opacity-60 dark:border-gray-700 dark:bg-gray-900 dark:text-gray-300"
          :disabled="loading || refreshing"
          @click="load(true)"
        >
          <svg :class="['h-4 w-4', refreshing && 'animate-spin']" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M21 12a9 9 0 1 1-2.64-6.36M21 4v5h-5" stroke-linecap="round" stroke-linejoin="round" />
          </svg>
          Actualiser
        </button>
      </div>

      <div v-if="error" class="rounded-lg border border-error-200 bg-error-50 px-4 py-3 text-error-700">
        {{ error }}
      </div>

      <!-- Squelette de chargement -->
      <div v-if="loading" class="space-y-6">
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <div v-for="i in 4" :key="i" class="h-36 animate-pulse rounded-2xl bg-gray-100 dark:bg-gray-800" />
        </div>
        <div class="h-80 animate-pulse rounded-2xl bg-gray-100 dark:bg-gray-800" />
      </div>

      <template v-else>
        <!-- Chiffres clés -->
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <div class="relative overflow-hidden rounded-2xl bg-brand-500 p-5 text-white shadow-theme-md dark:bg-brand-600">
            <div class="absolute -right-8 -top-8 h-32 w-32 rounded-full bg-white/10" />
            <div class="absolute -bottom-10 right-10 h-24 w-24 rounded-full bg-white/5" />
            <p class="relative text-sm text-white/75">Recette du jour</p>
            <p class="relative mt-2 text-3xl font-semibold tracking-tight">{{ money(stats.today_revenue) }}</p>
            <div class="relative mt-3 flex flex-wrap items-center gap-2 text-xs">
              <span class="rounded-full bg-white/15 px-2 py-0.5">{{ plural(stats.today_sales_count, 'vente') }}</span>
              <span
                v-if="todayTrend"
                :class="['rounded-full px-2 py-0.5 font-medium', todayTrend.up ? 'bg-success-500/25 text-success-50' : 'bg-error-500/25 text-error-50']"
              >
                {{ todayTrend.up ? '▲' : '▼' }} {{ todayTrend.text }}
              </span>
            </div>
          </div>

          <div :class="card">
            <div class="flex items-center justify-between">
              <p class="text-sm text-gray-500 dark:text-gray-400">Ce mois-ci</p>
              <span class="flex h-9 w-9 items-center justify-center rounded-xl bg-brand-50 text-brand-500 dark:bg-white/5 dark:text-brand-300">
                <svg class="h-5 w-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="5" width="18" height="16" rx="2" /><path d="M16 3v4M8 3v4M3 10h18" stroke-linecap="round" /></svg>
              </span>
            </div>
            <p class="mt-2 text-2xl font-semibold text-gray-800 dark:text-white">{{ money(stats.month_revenue) }}</p>
            <p class="mt-2 text-xs text-gray-500 dark:text-gray-400">
              {{ plural(stats.month_sales_count, 'vente') }} · mois dernier : {{ money(stats.last_month_revenue) }}
            </p>
          </div>

          <div :class="card">
            <div class="flex items-center justify-between">
              <p class="text-sm text-gray-500 dark:text-gray-400">Gagné depuis le début</p>
              <span class="flex h-9 w-9 items-center justify-center rounded-xl bg-success-50 text-success-600 dark:bg-success-500/15 dark:text-success-400">
                <svg class="h-5 w-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 17l6-6 4 4 8-8M15 7h6v6" stroke-linecap="round" stroke-linejoin="round" /></svg>
              </span>
            </div>
            <p class="mt-2 text-2xl font-semibold text-gray-800 dark:text-white">{{ money(stats.total_revenue) }}</p>
            <p class="mt-2 text-xs text-gray-500 dark:text-gray-400">{{ sinceLabel }} · {{ plural(stats.total_sales_count, 'vente') }}</p>
          </div>

          <div :class="card">
            <div class="flex items-center justify-between">
              <p class="text-sm text-gray-500 dark:text-gray-400">Panier moyen</p>
              <span class="flex h-9 w-9 items-center justify-center rounded-xl bg-warning-50 text-warning-600 dark:bg-warning-500/15 dark:text-warning-400">
                <svg class="h-5 w-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 6h15l-1.5 9h-12zM6 6L5 3H2M9 20a1 1 0 1 0 0-2 1 1 0 0 0 0 2zM18 20a1 1 0 1 0 0-2 1 1 0 0 0 0 2z" stroke-linecap="round" stroke-linejoin="round" /></svg>
              </span>
            </div>
            <p class="mt-2 text-2xl font-semibold text-gray-800 dark:text-white">{{ money(stats.average_basket) }}</p>
            <p class="mt-2 text-xs text-gray-500 dark:text-gray-400">Montant moyen d'une vente encaissée</p>
          </div>
        </div>

        <!-- Indicateurs rapides -->
        <div class="grid grid-cols-2 gap-3 md:grid-cols-3 xl:grid-cols-6">
          <RouterLink
            v-for="item in miniStats"
            :key="item.label"
            :to="item.to"
            class="rounded-xl border border-gray-200 bg-white px-4 py-3 transition hover:border-brand-300 dark:border-gray-800 dark:bg-white/[0.03] dark:hover:border-gray-600"
          >
            <p class="text-xs text-gray-500 dark:text-gray-400">{{ item.label }}</p>
            <p :class="['mt-1 text-xl font-semibold', item.accent ? 'text-warning-600 dark:text-warning-400' : 'text-gray-800 dark:text-white']">
              {{ item.value }}
            </p>
            <p v-if="item.hint" class="text-xs text-success-600 dark:text-success-400">{{ item.hint }}</p>
          </RouterLink>
        </div>

        <!-- Recettes récentes + statuts -->
        <div class="grid grid-cols-1 gap-6 xl:grid-cols-3">
          <div :class="[card, 'xl:col-span-2']">
            <div class="flex flex-wrap items-start justify-between gap-3">
              <div>
                <h2 class="text-lg font-semibold text-gray-800 dark:text-white">Recettes par jour</h2>
                <p class="text-sm text-gray-500 dark:text-gray-400">
                  {{ money(periodTotal) }} sur les {{ period }} derniers jours
                </p>
              </div>
              <div class="flex rounded-lg bg-gray-100 p-1 dark:bg-gray-900">
                <button
                  v-for="p in [7, 30] as const"
                  :key="p"
                  type="button"
                  :class="[
                    'rounded-md px-3 py-1 text-sm font-medium transition',
                    period === p ? 'bg-white text-gray-800 shadow-theme-xs dark:bg-gray-800 dark:text-white' : 'text-gray-500 dark:text-gray-400',
                  ]"
                  @click="period = p"
                >
                  {{ p }} jours
                </button>
              </div>
            </div>
            <VueApexCharts type="area" height="300" :options="revenueChart.options" :series="revenueChart.series" />
          </div>

          <div :class="card">
            <h2 class="text-lg font-semibold text-gray-800 dark:text-white">Commandes par statut</h2>
            <p class="text-sm text-gray-500 dark:text-gray-400">Toutes les commandes reçues</p>
            <div v-if="!statusChart.series.length" class="py-16 text-center text-sm text-gray-500">Aucune commande</div>
            <VueApexCharts v-else type="donut" height="300" :options="statusChart.options" :series="statusChart.series" />
          </div>
        </div>

        <!-- Depuis le lancement -->
        <div class="grid grid-cols-1 gap-6 xl:grid-cols-2">
          <div :class="card">
            <h2 class="text-lg font-semibold text-gray-800 dark:text-white">Gains cumulés depuis le lancement</h2>
            <p class="text-sm text-gray-500 dark:text-gray-400">{{ sinceLabel }}</p>
            <div v-if="!stats.sales_since_start.length" class="py-16 text-center text-sm text-gray-500">
              La courbe apparaîtra dès la première vente encaissée.
            </div>
            <VueApexCharts v-else type="area" height="280" :options="cumulativeChart.options" :series="cumulativeChart.series" />
          </div>

          <div :class="card">
            <h2 class="text-lg font-semibold text-gray-800 dark:text-white">Recettes par mois</h2>
            <p class="text-sm text-gray-500 dark:text-gray-400">Montant encaissé chaque mois</p>
            <VueApexCharts type="bar" height="280" :options="monthlyChart.options" :series="monthlyChart.series" />
          </div>
        </div>

        <!-- Meilleures ventes + catégories -->
        <div class="grid grid-cols-1 gap-6 xl:grid-cols-2">
          <div :class="card">
            <h2 class="text-lg font-semibold text-gray-800 dark:text-white">Meilleures ventes</h2>
            <p class="mb-4 text-sm text-gray-500 dark:text-gray-400">Articles les plus vendus (commandes payées)</p>
            <div v-if="!stats.top_products.length" class="py-10 text-center text-sm text-gray-500">Aucune vente pour le moment</div>
            <ul class="space-y-4">
              <li v-for="(p, i) in stats.top_products" :key="p.name" class="flex items-center gap-3">
                <span
                  :class="[
                    'flex h-8 w-8 shrink-0 items-center justify-center rounded-full text-sm font-semibold',
                    i === 0 ? 'bg-brand-500 text-white' : 'bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-300',
                  ]"
                >
                  {{ i + 1 }}
                </span>
                <div class="min-w-0 flex-1">
                  <div class="flex items-baseline justify-between gap-2">
                    <p class="truncate font-medium text-gray-800 dark:text-white">{{ p.name }}</p>
                    <p class="shrink-0 text-sm font-semibold text-gray-800 dark:text-white">{{ money(p.revenue) }}</p>
                  </div>
                  <div class="mt-1.5 flex items-center gap-2">
                    <div class="h-1.5 flex-1 overflow-hidden rounded-full bg-gray-100 dark:bg-gray-800">
                      <div class="h-full rounded-full bg-brand-300" :style="{ width: `${(p.quantity / topMax) * 100}%` }" />
                    </div>
                    <span class="w-20 shrink-0 text-right text-xs text-gray-500">{{ plural(p.quantity, 'vendu') }}</span>
                  </div>
                </div>
              </li>
            </ul>
          </div>

          <div :class="card">
            <h2 class="text-lg font-semibold text-gray-800 dark:text-white">Ventes par catégorie</h2>
            <p class="text-sm text-gray-500 dark:text-gray-400">Montant des articles vendus, hors livraison</p>
            <div v-if="!categoryChart.series.length" class="py-16 text-center text-sm text-gray-500">Aucune vente pour le moment</div>
            <VueApexCharts v-else type="donut" height="300" :options="categoryChart.options" :series="categoryChart.series" />
          </div>
        </div>

        <!-- Dernières commandes + stock -->
        <div class="grid grid-cols-1 gap-6 xl:grid-cols-3">
          <div :class="[card, 'xl:col-span-2']">
            <div class="mb-2 flex items-center justify-between">
              <h2 class="text-lg font-semibold text-gray-800 dark:text-white">Dernières commandes</h2>
              <RouterLink to="/orders" class="text-sm font-medium text-brand-500 hover:underline dark:text-brand-300">Tout voir</RouterLink>
            </div>
            <div v-if="!stats.latest_orders.length" class="py-10 text-center text-sm text-gray-500">Aucune commande</div>
            <ul class="divide-y divide-gray-100 dark:divide-gray-800">
              <li v-for="order in stats.latest_orders" :key="order.id" class="flex items-center justify-between gap-3 py-3">
                <div class="min-w-0">
                  <p class="font-medium text-gray-800 dark:text-white">{{ order.reference }}</p>
                  <p class="truncate text-xs text-gray-500">{{ order.customer_name }} · {{ formatDate(order.created_at) }}</p>
                </div>
                <div class="flex shrink-0 items-center gap-3">
                  <span :class="['rounded-full px-2.5 py-0.5 text-xs font-medium', statusMeta[order.status]?.badge ?? 'bg-gray-100 text-gray-600']">
                    {{ statusMeta[order.status]?.label ?? order.status }}
                  </span>
                  <p class="w-28 text-right font-semibold text-gray-800 dark:text-white">{{ money(Number(order.total)) }}</p>
                </div>
              </li>
            </ul>
          </div>

          <div :class="card">
            <div class="mb-2 flex items-center justify-between">
              <h2 class="text-lg font-semibold text-gray-800 dark:text-white">Stock faible</h2>
              <RouterLink to="/products" class="text-sm font-medium text-brand-500 hover:underline dark:text-brand-300">Gérer</RouterLink>
            </div>
            <div v-if="!stats.low_stock.length" class="py-10 text-center text-sm text-success-600">Tous les stocks sont bons</div>
            <ul class="divide-y divide-gray-100 dark:divide-gray-800">
              <li v-for="p in stats.low_stock" :key="p.id" class="flex items-center justify-between gap-3 py-3">
                <p class="truncate font-medium text-gray-800 dark:text-white">{{ p.name }}</p>
                <span
                  :class="[
                    'shrink-0 rounded-full px-2.5 py-0.5 text-xs font-medium',
                    Number(p.stock) <= 0
                      ? 'bg-error-50 text-error-700 dark:bg-error-500/15 dark:text-error-400'
                      : 'bg-warning-50 text-warning-700 dark:bg-warning-500/15 dark:text-warning-400',
                  ]"
                >
                  {{ Number(p.stock) <= 0 ? 'Rupture' : `${p.stock} restant${Number(p.stock) > 1 ? 's' : ''}` }}
                </span>
              </li>
            </ul>
          </div>
        </div>

        <p class="text-xs text-gray-400">
          Les recettes comptent les commandes payées (hors annulées), à la date de l'encaissement. Actualisation automatique toutes les 2 minutes.
        </p>
      </template>
    </div>
  </AdminLayout>
</template>
