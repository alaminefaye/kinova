import { createRouter, createWebHistory } from 'vue-router'
import { getToken } from '@/api/client'

const router = createRouter({
  history: createWebHistory('/dashboard/admin/'),
  scrollBehavior(to, from, savedPosition) {
    return savedPosition || { left: 0, top: 0 }
  },
  routes: [
    {
      path: '/',
      name: 'Dashboard',
      component: () => import('../views/Admin/DashboardHome.vue'),
      meta: { title: 'Dashboard', requiresAuth: true },
    },
    {
      path: '/products',
      name: 'Products',
      component: () => import('../views/Admin/ProductsPage.vue'),
      meta: { title: 'Produits', requiresAuth: true },
    },
    {
      path: '/categories',
      name: 'Categories',
      component: () => import('../views/Admin/CategoriesPage.vue'),
      meta: { title: 'Catégories', requiresAuth: true },
    },
    {
      path: '/hero-slides',
      name: 'HeroSlides',
      component: () => import('../views/Admin/HeroSlidesPage.vue'),
      meta: { title: 'Slider Accueil', requiresAuth: true },
    },
    {
      path: '/orders',
      name: 'Orders',
      component: () => import('../views/Admin/OrdersPage.vue'),
      meta: { title: 'Commandes', requiresAuth: true },
    },
    {
      path: '/notifications',
      name: 'Notifications',
      component: () => import('../views/Admin/NotificationsPage.vue'),
      meta: { title: 'Notifications', requiresAuth: true },
    },
    {
      path: '/contact-messages',
      name: 'ContactMessages',
      component: () => import('../views/Admin/ContactMessagesPage.vue'),
      meta: { title: 'Messages', requiresAuth: true },
    },
    {
      path: '/loyalty',
      name: 'Loyalty',
      component: () => import('../views/Admin/LoyaltyPage.vue'),
      meta: { title: 'Fidélité', requiresAuth: true },
    },
    {
      path: '/users',
      name: 'Users',
      component: () => import('../views/Admin/UsersPage.vue'),
      meta: { title: 'Utilisateurs', requiresAuth: true },
    },
    {
      path: '/roles',
      name: 'Roles',
      component: () => import('../views/Admin/RolesPage.vue'),
      meta: { title: 'Rôles & Permissions', requiresAuth: true },
    },
    {
      path: '/signin',
      name: 'Signin',
      component: () => import('../views/Auth/Signin.vue'),
      meta: { title: 'Connexion', guest: true },
    },
    {
      path: '/:pathMatch(.*)*',
      name: 'NotFound',
      component: () => import('../views/Errors/FourZeroFour.vue'),
      meta: { title: '404' },
    },
  ],
})

router.beforeEach((to, from, next) => {
  document.title = `${to.meta.title || 'Dashboard'} | KINOVA`
  const token = getToken()

  if (to.meta.requiresAuth && !token) {
    next({ name: 'Signin' })
    return
  }

  if (to.meta.guest && token) {
    next({ name: 'Dashboard' })
    return
  }

  next()
})

export default router
