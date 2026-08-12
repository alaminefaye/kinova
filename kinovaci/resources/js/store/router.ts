import { createRouter, createWebHistory } from 'vue-router'
import { getToken } from './api/client'

const router = createRouter({
  history: createWebHistory('/'),
  scrollBehavior() {
    return { top: 0 }
  },
  routes: [
    {
      path: '/',
      name: 'home',
      component: () => import('./pages/HomePage.vue'),
      meta: { title: 'Accueil' },
    },
    {
      path: '/boutique',
      name: 'catalog',
      component: () => import('./pages/CatalogPage.vue'),
      meta: { title: 'Boutique' },
    },
    {
      path: '/produit/:id',
      name: 'product',
      component: () => import('./pages/ProductPage.vue'),
      meta: { title: 'Produit' },
    },
    {
      path: '/panier',
      name: 'cart',
      component: () => import('./pages/CartPage.vue'),
      meta: { title: 'Panier' },
    },
    {
      path: '/commande',
      name: 'checkout',
      component: () => import('./pages/CheckoutPage.vue'),
      meta: { title: 'Commande' },
    },
    {
      path: '/commande/succes/:reference',
      name: 'order-success',
      component: () => import('./pages/OrderSuccessPage.vue'),
      meta: { title: 'Commande confirmée', hideChrome: true },
    },
    {
      path: '/connexion',
      name: 'auth',
      component: () => import('./pages/AuthPage.vue'),
      meta: { title: 'Connexion', hideChrome: true },
    },
    {
      path: '/compte',
      name: 'account',
      component: () => import('./pages/AccountPage.vue'),
      meta: { title: 'Compte', requiresAuth: true },
    },
    {
      path: '/favoris',
      name: 'favorites',
      component: () => import('./pages/FavoritesPage.vue'),
      meta: { title: 'Favoris' },
    },
    {
      path: '/recherche',
      name: 'search',
      component: () => import('./pages/SearchPage.vue'),
      meta: { title: 'Recherche' },
    },
    {
      path: '/notifications',
      name: 'notifications',
      component: () => import('./pages/NotificationsPage.vue'),
      meta: { title: 'Notifications' },
    },
    {
      path: '/:pathMatch(.*)*',
      redirect: '/',
    },
  ],
})

router.beforeEach((to, _from, next) => {
  document.title = `${to.meta.title || 'Boutique'} | KINOVA`
  if (to.meta.requiresAuth && !getToken()) {
    next({ name: 'auth', query: { redirect: to.fullPath } })
    return
  }
  next()
})

export default router
