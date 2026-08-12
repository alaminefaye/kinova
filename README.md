# KINOVA

```
kinova/
├── kinovaci/         Laravel = API + Dashboard admin Vue
└── kinova_mobile/    Flutter branché sur l’API prod
```

## Production

- Dashboard / API : [https://kinovaci.com/](https://kinovaci.com/)
- Base API mobile : `https://kinovaci.com/api`

## Web (backend + dashboard)

Voir procédure : [`kinovaci/API.md`](kinovaci/API.md)

Admin : `admin@kinova.test` / `password`

## Mobile

```bash
cd kinova_mobile
flutter pub get
flutter run
```

L’app charge catalogue, auth, favoris, commandes, notifications et contact depuis la prod.

Compte client démo : `client@kinova.test` / `password`

Config URL : `lib/api/api_config.dart`
