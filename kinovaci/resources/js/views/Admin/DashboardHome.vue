<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { api } from '@/api/client'

const router = useRouter()
const loading = ref(true)
const error = ref('')
const stats = reactive({
  products_count: 0,
  categories_count: 0,
  orders_count: 0,
  pending_orders: 0,
  revenue: 0,
  latest_orders: [] as any[],
  low_stock: [] as any[],
})

async function load() {
  loading.value = true
  error.value = ''
  try {
    const res = await api<{ data: typeof stats }>('/admin/dashboard')
    Object.assign(stats, res.data)
  } catch (e: any) {
    error.value = e.message || 'Erreur'
    if (String(e.message).includes('Unauthenticated') || String(e.message).includes('admin')) {
      router.push('/signin')
    }
  } finally {
    loading.value = false
  }
}

onMounted(load)

const money = (v: number) =>
  new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'XOF', maximumFractionDigits: 0 }).format(v || 0)
</script>

<template>
  <AdminLayout>
    <div class="space-y-6">
      <div>
        <h1 class="text-2xl font-semibold text-gray-800 dark:text-white">Dashboard KINOVA</h1>
        <p class="text-sm text-gray-500 mt-1">Vue d’ensemble boutique</p>
      </div>

      <div v-if="error" class="rounded-lg border border-error-200 bg-error-50 px-4 py-3 text-error-700">
        {{ error }}
      </div>

      <div v-if="loading" class="text-gray-500">Chargement…</div>

      <template v-else>
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <div class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03]">
            <p class="text-sm text-gray-500">Produits</p>
            <p class="mt-2 text-3xl font-semibold text-gray-800 dark:text-white">{{ stats.products_count }}</p>
          </div>
          <div class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03]">
            <p class="text-sm text-gray-500">Catégories</p>
            <p class="mt-2 text-3xl font-semibold text-gray-800 dark:text-white">{{ stats.categories_count }}</p>
          </div>
          <div class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03]">
            <p class="text-sm text-gray-500">Commandes</p>
            <p class="mt-2 text-3xl font-semibold text-gray-800 dark:text-white">{{ stats.orders_count }}</p>
            <p class="mt-1 text-xs text-brand-500">{{ stats.pending_orders }} en attente</p>
          </div>
          <div class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03]">
            <p class="text-sm text-gray-500">CA</p>
            <p class="mt-2 text-3xl font-semibold text-gray-800 dark:text-white">{{ money(stats.revenue) }}</p>
          </div>
        </div>

        <div class="grid grid-cols-1 gap-6 xl:grid-cols-2">
          <div class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03]">
            <h2 class="mb-4 text-lg font-semibold text-gray-800 dark:text-white">Dernières commandes</h2>
            <div v-if="!stats.latest_orders.length" class="text-sm text-gray-500">Aucune commande</div>
            <ul class="divide-y divide-gray-100 dark:divide-gray-800">
              <li v-for="order in stats.latest_orders" :key="order.id" class="flex items-center justify-between py-3">
                <div>
                  <p class="font-medium text-gray-800 dark:text-white">{{ order.reference }}</p>
                  <p class="text-xs text-gray-500">{{ order.customer_name }} · {{ order.status }}</p>
                </div>
                <p class="font-semibold text-gray-800 dark:text-white">{{ money(Number(order.total)) }}</p>
              </li>
            </ul>
          </div>

          <div class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03]">
            <h2 class="mb-4 text-lg font-semibold text-gray-800 dark:text-white">Stock faible</h2>
            <div v-if="!stats.low_stock.length" class="text-sm text-gray-500">Stock OK</div>
            <ul class="divide-y divide-gray-100 dark:divide-gray-800">
              <li v-for="p in stats.low_stock" :key="p.id" class="flex items-center justify-between py-3">
                <p class="font-medium text-gray-800 dark:text-white">{{ p.name }}</p>
                <p class="text-sm text-error-500">{{ p.stock }} restants</p>
              </li>
            </ul>
          </div>
        </div>
      </template>
    </div>
  </AdminLayout>
</template>
