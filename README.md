# CasaImo

> Plateforme de location immobilière pour l'Afrique de l'Ouest — recherche, réservation et paiement de logements entre propriétaires et locataires.

![Version](https://img.shields.io/badge/version-1.0.0-green)
![Flutter](https://img.shields.io/badge/Flutter-3.38.9-blue)
![Dart](https://img.shields.io/badge/Dart-3.10.8-blue)
![Firebase](https://img.shields.io/badge/Firebase-✓-orange)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-lightgrey)

---

## Présentation

**CasaImo** connecte deux profils :

| Profil | Ce qu'il fait |
|---|---|
| **Client / Locataire** | Recherche, filtre, consulte les annonces, réserve et paie |
| **Propriétaire / Hôte** | Publie des annonces avec photos/vidéo, gère les réservations et son profil entreprise |

Marchés cibles : Bénin · Togo · Côte d'Ivoire · Sénégal · Burkina Faso

---

## Stack technique

| Couche | Technologie |
|---|---|
| Framework | Flutter 3.38.9 / Dart 3.10.8 |
| State management | Riverpod 2.5.1 (`StateNotifierProvider`, `StreamProvider`, `FutureProvider`) |
| Navigation | go_router 13.x (ShellRoute client + ShellRoute hôte, deep links) |
| Backend | Firebase — Auth · Firestore · Storage · Messaging (FCM) · Crashlytics |
| Auth | Email/Password · Google Sign-In · Téléphone OTP |
| Stockage médias | Firebase Storage — Photos et vidéos des annonces |
| Maps | Google Maps Flutter + Geolocator + Geocoding |
| UI | cached_network_image · shimmer · carousel_slider · flutter_rating_bar |
| Animations | flutter_animate 4.5 · video_player (splash MP4) |
| Serialisation | Freezed · json_serializable |
| Upload | image_picker + firebase_storage (avec barre de progression) |

---

## Architecture

Clean Architecture organisée par feature :

```
lib/
├── main.dart                              # Entry point — Firebase init + ProviderScope
│
├── core/
│   ├── config/
│   │   ├── app_constants.dart             # Listes : 9 types de biens, 22 équipements, icônes
│   │   └── firebase_options.dart          # Config Firebase multi-plateformes (auto-généré)
│   ├── router/
│   │   └── app_router.dart                # go_router : 25+ routes, redirect par rôle
│   ├── services/
│   │   └── storage_service.dart           # Upload photo/vidéo vers Firebase Storage
│   ├── theme/
│   │   ├── app_colors.dart                # Palette vert CasaImo (#2E7D32 / #22C55E)
│   │   ├── app_text_styles.dart           # Styles Poppins
│   │   └── app_theme.dart                 # ThemeData light + dark
│   └── utils/
│       └── app_utils.dart                 # formatPrice, formatDate, timeAgo…
│
├── shared/
│   └── widgets/
│       ├── cards/listing_card.dart        # Card annonce (vertical, horizontal, skeleton)
│       ├── inputs/search_bar_widget.dart  # Barre de recherche réutilisable
│       └── layout/
│           ├── app_scaffold.dart          # Shell client — BottomNav 5 onglets
│           ├── host_app_scaffold.dart     # Shell hôte — BottomNav 5 onglets
│           ├── section_header.dart        # Titre section + "Voir plus"
│           ├── empty_state.dart           # État vide générique
│           └── shimmer_loader.dart        # Squelette de chargement
│
└── features/
    ├── auth/
    │   ├── data/models/user_model.dart    # UserModel avec champs business + hasBusiness
    │   └── presentation/
    │       ├── providers/auth_provider.dart
    │       └── screens/
    │           ├── splash_screen.dart     # Splash MP4 via video_player (5s)
    │           ├── onboarding_screen.dart # 3 slides d'introduction
    │           ├── role_selection_screen.dart  # Choix Client / Propriétaire
    │           ├── login_screen.dart      # Email + Google + OTP
    │           ├── client_signup_screen.dart
    │           ├── host_signup_screen.dart
    │           └── otp_screen.dart        # Vérification SMS
    │
    ├── home/
    │   └── presentation/
    │       ├── providers/home_provider.dart
    │       └── screens/home_screen.dart   # Feed dynamique avec carrousel
    │
    ├── search/
    │   └── presentation/
    │       ├── providers/search_provider.dart   # SearchFilters + résultats filtrés
    │       └── screens/
    │           ├── search_screen.dart
    │           └── search_results_screen.dart
    │
    ├── listing/
    │   ├── data/
    │   │   ├── models/listing_model.dart  # 30+ champs dont hostPhone/Email dénormalisés
    │   │   └── repositories/listing_repository.dart
    │   └── presentation/
    │       ├── providers/listing_provider.dart
    │       └── screens/listing_detail_screen.dart   # Galerie · Carte hôte · Réservation
    │
    ├── booking/
    │   ├── data/models/booking_model.dart
    │   └── presentation/screens/
    │       ├── booking_screen.dart        # Wizard 3 étapes (dates → résumé → paiement)
    │       └── booking_confirmation_screen.dart
    │
    ├── host/
    │   └── presentation/
    │       ├── providers/host_provider.dart         # hostByIdProvider, hostListingsStreamProvider
    │       └── screens/
    │           ├── host_own_profile_screen.dart     # Profil hôte (vue personnelle)
    │           ├── host_public_profile_screen.dart  # Profil hôte (vue client)
    │           ├── create_listing_screen.dart       # Wizard 6 étapes + upload Firebase
    │           ├── host_listings_screen.dart        # Liste annonces hôte en temps réel
    │           ├── host_dashboard_screen.dart       # KPIs + actions rapides
    │           ├── host_calendar_screen.dart        # Calendrier de disponibilité
    │           └── host_bookings_screen.dart        # Pipeline réservations
    │
    ├── profile/
    │   └── presentation/screens/
    │       ├── profile_screen.dart
    │       ├── favorites_screen.dart
    │       └── booking_history_screen.dart
    │
    ├── messaging/
    │   ├── data/models/message_model.dart
    │   └── presentation/screens/
    │       ├── conversations_screen.dart
    │       └── chat_screen.dart
    │
    └── notifications/
        └── presentation/screens/
            └── notifications_screen.dart
```

---

## Modèles de données

### UserModel (`users/{userId}`)

| Champ | Type | Description |
|---|---|---|
| `id` | String | UID Firebase Auth |
| `email` | String | Email |
| `phone` | String | Téléphone |
| `name` | String | Nom complet |
| `avatarUrl` | String | Photo de profil |
| `role` | String | `client` ou `host` |
| `isVerified` | bool | Badge KYC vérifié |
| `businessName` | String | Nom de l'entreprise (hôte) |
| `businessType` | String | Type d'activité |
| `businessAddress` | String | Adresse professionnelle |
| `businessDescription` | String | Description |
| `hasBusiness` | bool *(getter)* | `businessName.isNotEmpty` |

### ListingModel (`listings/{listingId}`)

| Champ | Type | Description |
|---|---|---|
| `hostId` | String | UID du propriétaire |
| `hostName` | String | Nom hôte (dénormalisé) |
| `hostPhone` | String | Téléphone hôte (dénormalisé) |
| `hostEmail` | String | Email hôte (dénormalisé) |
| `hostBusinessType` | String | Type activité (dénormalisé) |
| `hostBusinessAddress` | String | Adresse pro (dénormalisé) |
| `hostIsVerified` | bool | Badge vérifié (dénormalisé) |
| `type` | String | Parmi les 9 types |
| `mediaUrls` | List\<String\> | URLs Firebase Storage |
| `videoUrl` | String | URL vidéo Firebase Storage |
| `pricePerNight` | double | Prix/nuit (FCFA) |
| `pricePerMonth` | double | Prix/mois (FCFA) |
| `cancellationPolicy` | String | `flexible` / `moderate` / `strict` |
| `status` | String | `published` / `draft` / `paused` |

> **Dénormalisation** : les 5 champs `host*` sont copiés dans chaque annonce au moment de la publication. Cela garantit que l'affichage sur la page détail ne nécessite pas de requête Firestore supplémentaire et qu'aucune annonce n'est jamais anonyme.

### Schéma Firestore complet

```
users/{userId}
listings/{listingId}
  └── availability/{date}         # Jours bloqués
bookings/{bookingId}
messages/{conversationId}
  └── msgs/{msgId}
reviews/{reviewId}
notifications/{notifId}
```

---

## Firebase Storage

Bucket : `casaimo.firebasestorage.app`

| Chemin | Contenu | Règle |
|---|---|---|
| `listings/{hostId}/*.jpg` | Photos annonces | Lecture publique · Écriture = auth.uid == hostId |
| `listings/{hostId}/videos/*.mp4` | Vidéos annonces | Même règle · max 100 MB |
| `avatars/{userId}/*` | Photos profil | Écriture = auth.uid == userId · max 5 MB |
| `logos/{userId}/*` | Logos entreprise | Écriture = auth.uid == userId · max 5 MB |

Déployer les règles : `firebase deploy --only storage`

---

## Parcours utilisateur

### Côté Client

```
Splash (MP4 5s)
  → Onboarding (3 slides)
  → Choix de rôle
  → Login / Inscription
  → Accueil (feed annonces)
  → Recherche / Filtres
  → Détail annonce
      ├── Galerie photos + vidéo
      ├── Carte hôte (téléphone direct · email · "Toutes les offres")
      └── Réservation (dates → résumé → paiement)
  → Profil hôte public → toutes ses annonces
```

### Côté Hôte / Propriétaire

```
Dashboard
  → Créer une annonce (wizard 6 étapes)
      1. Catégorie (9 types avec icônes)
      2. Infos (titre · description · adresse)
      3. Médias (photos + vidéo 1min via Firebase Storage)
      4. Équipements (22 options)
      5. Tarification (nuit + mois + frais de ménage)
      6. Aperçu avant publication
  → Mes annonces (liste temps réel Firestore)
  → Réservations (pipeline)
  → Calendrier
  → Profil entreprise (infos · logo · badge KYC)
```

---

## Routes (go_router)

| Route | Écran | Accès |
|---|---|---|
| `/` | SplashScreen | Tous |
| `/onboarding` | OnboardingScreen | Tous |
| `/role-select` | RoleSelectionScreen | Non-auth |
| `/login` | LoginScreen | Non-auth |
| `/signup/client` | ClientSignupScreen | Non-auth |
| `/signup/host` | HostSignupScreen | Non-auth |
| `/otp` | OtpScreen | Non-auth |
| `/home` | HomeScreen | Client |
| `/search` | SearchScreen | Client |
| `/listing/:id` | ListingDetailScreen | Client |
| `/host-profile/:hostId` | HostPublicProfileScreen | Client |
| `/host/dashboard` | HostDashboardScreen | Hôte |
| `/host/listings` | HostListingsScreen | Hôte |
| `/host/create` | CreateListingScreen | Hôte |
| `/host/profile` | HostOwnProfileScreen | Hôte |
| `/host/bookings` | HostBookingsScreen | Hôte |
| `/host/calendar` | HostCalendarScreen | Hôte |

---

## Prérequis

- Flutter SDK ≥ 3.10.0
- Dart ≥ 3.10.0
- Android Studio / Xcode (pour build mobile)
- Projet Firebase `casaimo` (déjà configuré)
- Clé API Google Maps
- Firebase CLI : `npm install -g firebase-tools`
- Python 3.12+ (pour la vidéo splash uniquement)

---

## Installation

```bash
# 1. Cloner le projet
git clone <repo-url>
cd casaimo

# 2. Dépendances Flutter
flutter pub get

# 3. Lancer en développement
flutter run -d chrome        # Web
flutter run -d <device-id>   # Android / iOS

# 4. Analyser le code
flutter analyze --no-fatal-infos

# 5. Build production
flutter build apk --release         # Android APK
flutter build appbundle --release   # Android AAB (Play Store)
flutter build ipa --release         # iOS
flutter build web --release         # Web
```

---

## Configuration Firebase

### 1. Méthodes d'authentification (Firebase Console)

Firebase Console → Projet `casaimo` → Authentication → Sign-in method :

- [ ] Email / Mot de passe
- [ ] Google (nécessite SHA-1 dans les paramètres Android)
- [ ] Téléphone OTP

### 2. SHA-1 Android (Google Sign-In)

```bash
keytool -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android -keypass android
```

SHA-1 debug connu : `13:6B:C4:59:D6:EC:94:9C:40:BB:9B:D0:5D:8F:94:4D:74:8C:33:15`

### 3. Numéro de test SMS

Firebase Console → Authentication → Phone → Test phone numbers :
- Numéro : `+22960000000` · Code : `123456`

### 4. Firebase Storage

Firebase Console → Storage → Commencer (région : `europe-west1`)

Déployer les règles :
```bash
firebase deploy --only storage
```

### 5. Google Maps

`android/app/src/main/AndroidManifest.xml` :
```xml
<meta-data
  android:name="com.google.android.geo.API_KEY"
  android:value="VOTRE_CLE_API" />
```

---

## Vidéo splash

Le splash screen lit `assets/animations/splash.mp4` (5s, 1080×1920).

Pour régénérer la vidéo :
```bash
cd casaimo
python scripts/generate_splash.py
```

Dépendances Python requises : `opencv-python` · `Pillow` · `numpy` (déjà installés).

---

## Paiements (à intégrer)

| Méthode | Opérateurs |
|---|---|
| Mobile Money | MTN MoMo · Orange Money · Moov Money · Wave |
| Carte bancaire | Visa · Mastercard |

SDK recommandé pour l'Afrique de l'Ouest : **CinetPay** ou **Flutterwave**

---

## Commandes utiles

```bash
# Code quality
flutter analyze --no-fatal-infos
flutter test

# Firebase
firebase deploy --only firestore:rules
firebase deploy --only storage
firebase deploy --only firestore:indexes

# Nettoyage
flutter clean && flutter pub get

# Générer le code (Riverpod / Freezed)
dart run build_runner build --delete-conflicting-outputs

# Régénérer la vidéo splash
python scripts/generate_splash.py

# Icônes app
dart run flutter_launcher_icons
```

---

## Licence

Projet privé — © 2026 CasaImo. Tous droits réservés.
