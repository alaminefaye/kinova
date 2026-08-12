# KINOVA

```
kinova/
├── kinovaci/         ✅ Laravel = API + Dashboard admin Vue
└── kinova_mobile/    ✅ Flutter (données mock — pas encore branché API)
```

## Web (backend + dashboard)

Voir procédure complète : [`kinovaci/API.md`](kinovaci/API.md)

```bash
cd kinovaci
php artisan migrate:fresh --seed
npm run dev
php artisan serve
```

Admin : http://127.0.0.1:8000/signin  
`admin@kinova.test` / `password`

## Mobile

```bash
cd kinova_mobile
flutter run
```

Pour l’instant le mobile utilise des données locales. Connexion API = étape suivante.
# kinova
