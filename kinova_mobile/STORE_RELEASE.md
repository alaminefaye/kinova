# Publication KINOVA — Play Store & App Store

Guide pour publier l'application Flutter `kinova_mobile` sur **Google Play** et **App Store**.

## État actuel du projet

| Élément | Valeur |
|---------|--------|
| Package Android | `com.kinova.app` |
| Bundle ID iOS | `com.kinova.app` |
| Version | `1.0.0+1` (nom+build dans `pubspec.yaml`) |
| API production | `https://kinovaci.com/api` |
| Firebase project | `kinova-3d26a` |
| Équipe Apple (Xcode) | `89W2344QW3` |

---

## 1. Avant de commencer

### Comptes développeur

- **Google Play** : [Google Play Console](https://play.google.com/console) — frais unique ~25 USD
- **Apple** : [Apple Developer Program](https://developer.apple.com/programs/) — 99 USD/an

### Prérequis locaux

```bash
cd kinova_mobile
flutter pub get
dart run flutter_launcher_icons   # régénère les icônes si besoin
```

### Politique de confidentialité (obligatoire)

Page publique disponible :

→ **https://kinovaci.com/politique-confidentialite**

→ Support : **https://kinovaci.com/aide** — e-mail `contact@kinovaci.com`

Indiquez l’URL de la politique dans Play Console et App Store Connect.

---

## 2. Android — Google Play Store

### 2.1 Créer le keystore (une seule fois)

```bash
mkdir -p android/keystore
keytool -genkey -v \
  -keystore android/keystore/kinova-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias kinova
```

Conservez le fichier `.jks` et les mots de passe **en lieu sûr** (perte = impossible de mettre à jour l'app).

### 2.2 Configurer la signature

```bash
cp android/key.properties.example android/key.properties
# Éditez key.properties avec vos mots de passe et le chemin du keystore
```

### 2.3 Build AAB (Android App Bundle)

```bash
./scripts/build_release.sh android
# ou :
flutter build appbundle --release
```

Fichier produit : `build/app/outputs/bundle/release/app-release.aab`

### 2.4 Play Console — checklist

1. **Créer l'application** → nom KINOVA, langue par défaut français
2. **Fiche Play Store** : titre, descriptions, captures, icône 512×512  
   → textes prêts dans `store_listing/metadata.md`
3. **Classification du contenu** : questionnaire (shopping, pas de contenu sensible)
4. **Cible audience** : tout public
5. **Sécurité des données** : déclarer nom, email, téléphone, photos, achats (voir metadata.md)
6. **Production → Créer une version** → uploader le `.aab`
7. **Comptes de test** : ajouter des testeurs internes avant la prod si besoin

### Notes techniques Android

- HTTPS uniquement (`network_security_config.xml`) — plus de trafic HTTP clair
- ProGuard/R8 activé en release (`proguard-rules.pro`)
- Sans `key.properties`, le build release utilise la signature debug (non accepté en production)

---

## 3. iOS — App Store

### 3.1 App Store Connect

1. [App Store Connect](https://appstoreconnect.apple.com) → **Apps** → **+** Nouvelle app
2. Bundle ID : `com.kinova.app` (doit exister dans Certificates, Identifiers & Profiles)
3. SKU : ex. `kinova-ios-001`
4. Renseigner métadonnées (`store_listing/metadata.md`)

### 3.2 Certificats & profils

Avec Xcode (recommandé) :
1. Ouvrir `ios/Runner.xcworkspace`
2. Target **Runner** → **Signing & Capabilities**
3. Team : votre équipe (`89W2344QW3`)
4. **Automatically manage signing** : activé

### 3.3 Build IPA

```bash
./scripts/build_release.sh ios
# ou :
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
```

Ou via Xcode : **Product → Archive** → **Distribute App** → App Store Connect.

### 3.4 App Store Connect — checklist

1. **Informations sur l'app** : catégorie Shopping, politique de confidentialité URL
2. **Tarifs et disponibilité** : pays cibles (ex. Sénégal, France, etc.)
3. **Confidentialité de l'app** (Privacy Nutrition Labels) : aligné avec `PrivacyInfo.xcprivacy`
4. **Captures d'écran** iPhone 6.7" (minimum 3)
5. **Build** : sélectionner le build uploadé après traitement (~15–30 min)
6. **Export compliance** : `ITSAppUsesNonExemptEncryption = false` déjà dans Info.plist (HTTPS standard uniquement)
7. **Suppression de compte** : requis par Apple — déjà implémenté dans Profil

### Fichiers iOS ajoutés

- `ios/Runner/PrivacyInfo.xcprivacy` — manifeste confidentialité Apple
- `ios/ExportOptions.plist` — export App Store Connect

---

## Firebase (notifications push)

Fichiers configurés :

| Plateforme | Fichier |
|------------|---------|
| Android | `android/app/google-services.json` |
| iOS | `ios/Runner/GoogleService-Info.plist` |

Packages : `firebase_core`, `firebase_messaging`

### iOS — APNs (obligatoire pour les push)

1. [Apple Developer](https://developer.apple.com) → **Certificates, Identifiers & Profiles** → **Keys**
2. Créer une clé **Apple Push Notifications service (APNs)**
3. [Firebase Console](https://console.firebase.google.com) → projet **kinova-3d26a** → ⚙️ → **Cloud Messaging**
4. Uploader la clé APNs (.p8) dans la section **Apple app configuration**

### Backend

Migration à lancer en production :

```bash
php artisan migrate
```

**Credentials serveur (FCM)** — fichier compte de service Firebase :

1. Télécharger depuis Firebase Console → Paramètres projet → Comptes de service → Générer une nouvelle clé privée
2. Placer le fichier sur le serveur : `storage/app/private/firebase/service-account.json`
3. Variables `.env` :

```env
FIREBASE_PROJECT=app
FIREBASE_CREDENTIALS=storage/app/private/firebase/service-account.json
FIREBASE_PUSH_ENABLED=true
```

4. `php artisan config:clear`

Le serveur envoie automatiquement une **push FCM** à chaque notification créée (commande, promo admin, fidélité, etc.).

Routes API :
- `POST /api/customer/device-token` — enregistre le token FCM
- `POST /api/customer/device-token/remove` — supprime le token à la déconnexion

---

## 4. Incrémenter les versions

À chaque nouvelle soumission :

```yaml
# pubspec.yaml
version: 1.0.1+2   # 1.0.1 = nom visible, 2 = numéro de build (doit augmenter)
```

- **Android** : `versionCode` (= build number) doit **toujours augmenter**
- **iOS** : `CFBundleVersion` (= build number) doit **toujours augmenter**

---

## 5. Tests avant soumission

```bash
# Android release sur appareil
flutter run --release

# Vérifier
# ✓ Connexion / inscription (email + téléphone)
# ✓ Catalogue, panier, commande
# ✓ Upload photo profil
# ✓ Suppression de compte
# ✓ Aide & contact
# ✓ API https://kinovaci.com/api accessible
```

---

## 6. Espace administrateur dans l'app

L'app mobile inclut un **tableau de bord admin** pour les comptes administrateurs. Ce n'est **pas bloquant** pour la publication (comportement conditionnel au rôle). Pour une app 100 % client, vous pourriez retirer cette fonctionnalité dans une version ultérieure.

---

## 7. Fichiers sensibles (ne jamais commiter)

- `android/key.properties`
- `android/keystore/*.jks`
- Certificats Apple (`.p12`, profils `.mobileprovision`)

Ces chemins sont dans `.gitignore`.

---

## 8. Commandes rapides

```bash
cd kinova_mobile

# Icônes
dart run flutter_launcher_icons

# Build stores
chmod +x scripts/build_release.sh
./scripts/build_release.sh          # Android + iOS
./scripts/build_release.sh android  # Play Store seulement
./scripts/build_release.sh ios      # App Store seulement
```

---

## Support

Métadonnées store : `store_listing/metadata.md`  
Questions Play : [Centre d'aide Play Console](https://support.google.com/googleplay/android-developer)  
Questions App Store : [App Store Connect Help](https://developer.apple.com/help/app-store-connect/)
