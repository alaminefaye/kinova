# KINOVA — Backend & Dashboard (procédure)

> Mobile Flutter branché sur la prod : `https://kinovaci.com/api` (`kinova_mobile/lib/api/api_config.dart`).

## Structure

```
kinova/
├── kinovaci/         Laravel = API + Dashboard Vue admin
└── kinova_mobile/    Flutter (mock local pour l’instant)
```

## Lancer le backend + dashboard

```bash
cd kinovaci
composer install
cp .env.example .env   # si besoin
php artisan key:generate
touch database/database.sqlite
php artisan migrate:fresh --seed
php artisan storage:link
npm install
npm run dev            # terminal 1
php artisan serve      # terminal 2 → http://127.0.0.1:8000
```

### Admin dashboard

- URL : http://127.0.0.1:8000/signin  
- Email : `admin@kinova.test`  
- Mot de passe : `password`

Pages admin :
- `/` Dashboard
- `/products` CRUD + upload image
- `/categories` CRUD
- `/hero-slides` CRUD slider accueil
- `/orders` statut + tracking livraison
- `/notifications` envoi / historique
- `/contact-messages` aide & contact
- `/loyalty` points VIP clients

### Compte client démo (API)

- Email : `client@kinova.test`
- Mot de passe : `password`

## API disponibles (préfixe `/api`)

### Publique

| Méthode | Route | Description |
|---------|-------|-------------|
| GET | `/api/health` | Santé |
| GET | `/api/categories` | Liste catégories |
| GET | `/api/categories/{id}` | Détail + produits |
| GET | `/api/products` | Liste (`?category=`, `?featured=1`, `?new=1`, `?q=`) |
| GET | `/api/products/{id}` | Détail produit |
| GET | `/api/hero-slides` | Slides actifs du carrousel accueil |
| POST | `/api/orders` | Créer commande (optionnel Bearer client) |
| GET | `/api/orders/{reference}` | Suivi commande (tracking inclus) |
| GET | `/api/help` | FAQ + contacts |
| POST | `/api/contact` | Envoyer message aide |

### Auth admin

| Méthode | Route | Description |
|---------|-------|-------------|
| POST | `/api/auth/login` | Login admin |
| GET | `/api/auth/me` | User courant |
| POST | `/api/auth/logout` | Logout |

### Auth + espace client (Bearer)

| Méthode | Route | Description |
|---------|-------|-------------|
| POST | `/api/customer/auth/register` | Inscription |
| POST | `/api/customer/auth/login` | Login client |
| GET/PUT | `/api/customer/profile` | Profil (adresse, VIP) |
| GET/POST/DELETE | `/api/customer/favorites` | Favoris |
| POST | `/api/customer/favorites/sync` | Sync liste `product_ids` |
| GET | `/api/customer/orders` | Mes commandes |
| GET | `/api/customer/orders/{reference}` | Détail commande |
| GET | `/api/customer/notifications` | Notifications (+ `unread_count`) |
| POST | `/api/customer/notifications/{id}/read` | Marquer lue |
| POST | `/api/customer/notifications/read-all` | Tout lire |
| GET | `/api/customer/loyalty` | Points + historique |
| POST | `/api/customer/loyalty/redeem` | Échanger des points |

### Admin (Bearer + rôle `admin`)

| Méthode | Route | Description |
|---------|-------|-------------|
| GET | `/api/admin/dashboard` | Stats |
| CRUD | `/api/admin/categories` | Catégories |
| CRUD | `/api/admin/products` | Produits |
| CRUD | `/api/admin/hero-slides` | Slider accueil (app mobile) |
| GET/PUT | `/api/admin/orders` | Commandes / statut / tracking |
| POST | `/api/admin/media` | Upload image (`multipart` field `image`) |
| GET/POST/DELETE | `/api/admin/notifications` | Notifications |
| GET/PUT | `/api/admin/contact-messages` | Messages contact |
| GET | `/api/admin/loyalty/customers` | Clients + points |
| POST | `/api/admin/loyalty/customers/{id}/adjust` | ± points |

## Fidélité VIP

| Palier | Points min |
|--------|------------|
| standard | 0 |
| silver | 500 |
| gold | 1500 |
| vip | 3000 |

À la livraison d’une commande liée à un compte : **1 FCFA ≈ 1 point** (+ notification).

## Seed démo

- 4 catégories, 10 produits
- 1 admin + 1 client
- favoris, commande avec tracking, notifications, message contact, bonus points

## Mobile

L’app `kinova_mobile` utilise ces endpoints. Compte démo client : `client@kinova.test` / `password`.
