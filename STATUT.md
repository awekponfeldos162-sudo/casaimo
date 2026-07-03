# STATUT DU PROJET — CasaImo

> Dernière mise à jour : 23 juin 2026

---

## LEGENDE

| Symbole | Signification |
|---|---|
| ✅ | Terminé et fonctionnel |
| 🔶 | Partiellement fait — nécessite des ajustements |
| ❌ | Pas encore commencé |
| 🔧 | En cours / bloqué |

---

## 1. ARCHITECTURE & CORE

| Tâche | Statut | Notes |
|---|---|---|
| Architecture Clean (features/data/domain/presentation) | ✅ | |
| Riverpod 2.x — providers par feature | ✅ | |
| go_router 13 — ShellRoute client + hôte | ✅ | |
| Redirect par rôle (`client` / `host`) | ✅ | Fix : `/host-profile` exclu de la protection |
| Thème light/dark (Poppins, vert #2E7D32) | ✅ | |
| main.dart — Firebase init + orientation fixe | ✅ | |
| AppConstants — 9 types, 22 équipements, icônes | ✅ | |
| StorageService (upload photo + vidéo) | ✅ | |

---

## 2. AUTHENTIFICATION

| Tâche | Statut | Notes |
|---|---|---|
| SplashScreen — MP4 5s (video_player) | ✅ | `assets/animations/splash.mp4` |
| Script Python génération splash MP4 | ✅ | `scripts/generate_splash.py` |
| OnboardingScreen — 3 slides | ✅ | |
| RoleSelectionScreen — Client / Propriétaire | ✅ | Fix overflow petits écrans |
| LoginScreen — Email + Password | ✅ | |
| LoginScreen — Google Sign-In (UI) | 🔶 | UI faite · SHA-1 à configurer dans Firebase Console |
| LoginScreen — OTP téléphone | 🔶 | UI faite · activer méthode dans Firebase Console |
| LoginScreen — Mot de passe oublié | ✅ | Dialog + `sendPasswordResetEmail()` implémenté |
| OtpScreen — vérification SMS | ✅ | Multi-pays (indicatif libre, validation `startsWith('+')`) |
| ClientSignupScreen | ✅ | |
| HostSignupScreen | ✅ | |
| AuthNotifier (Riverpod) | ✅ | + méthode `refreshUser()` ajoutée |
| UserModel — champs business (`businessName`, `businessType`…) | ✅ | |
| UserModel — `hasBusiness` getter | ✅ | |

**Actions Firebase Console requises :**
- [ ] Activer Email/Password
- [ ] Activer Google Sign-In + ajouter SHA-1 (`13:6B:C4:59:D6:EC:94:9C:40:BB:9B:D0:5D:8F:94:4D:74:8C:33:15`) et SHA-256
- [ ] Activer Téléphone + ajouter numéro test

---

## 3. ESPACE CLIENT

| Tâche | Statut | Notes |
|---|---|---|
| HomeScreen — feed annonces | ✅ | |
| HomeScreen — carrousel featured | ✅ | |
| SearchScreen — barre + filtres rapides | ✅ | |
| SearchResultsScreen — liste + tri | ✅ | |
| ListingDetailScreen — galerie photos | ✅ | |
| ListingDetailScreen — lecture vidéo | ✅ | Bouton play + `url_launcher` |
| ListingDetailScreen — prix nuit + mois | ✅ | |
| ListingDetailScreen — carte hôte enrichie | ✅ | Avatar · badge vérifié · téléphone · email |
| ListingDetailScreen — "Toutes les offres" | ✅ | Lien vers `HostPublicProfileScreen` |
| ListingDetailScreen — "Autres offres" scroll | ✅ | |
| HostPublicProfileScreen — profil client | ✅ | Grille annonces · stats · contact |
| ProfileScreen — infos compte | ✅ | |
| FavoritesScreen | ✅ | Branché sur Firestore via `allListingsStreamProvider` |
| BookingScreen — Étape 1 : Dates | ✅ | |
| BookingScreen — Étape 2 : Récapitulatif | ✅ | |
| BookingScreen — Étape 3 : Paiement | ✅ | |
| BookingScreen — données Firestore réelles | ✅ | Utilise `listingByIdProvider`, écrit `bookings/` |
| BookingConfirmationScreen | ✅ | Affiche ID réel Firestore |
| BookingHistoryScreen | ✅ | StreamProvider — query `bookings` par `guestId` |

---

## 4. ESPACE HÔTE / PROPRIÉTAIRE

| Tâche | Statut | Notes |
|---|---|---|
| HostDashboardScreen — KPIs | ✅ | Comptage Firestore réel (annonces + réservations) |
| HostOwnProfileScreen — profil personnel | ✅ | Stats · badge KYC · infos business |
| HostOwnProfileScreen — édition profil | ✅ | Dialog Firestore + `refreshUser()` |
| CreateListingScreen — Étape 1 : Catégorie | ✅ | Grille 3×3 avec icônes |
| CreateListingScreen — Étape 2 : Infos | ✅ | |
| CreateListingScreen — Étape 3 : Médias | ✅ | Upload Firebase Storage avec progression |
| CreateListingScreen — Étape 4 : Équipements | ✅ | 22 équipements |
| CreateListingScreen — Étape 5 : Tarification | ✅ | Prix nuit + mois + frais + annulation |
| CreateListingScreen — Étape 6 : Aperçu | ✅ | |
| CreateListingScreen — mode édition | ✅ | Charge annonce existante + `update()` Firestore |
| Publication — dénormalisation 5 champs hôte | ✅ | `hostPhone`, `hostEmail`… dans chaque annonce |
| ListingModel.copyWith — tous les champs | ✅ | 19 champs éditables (ajout address, city, bedrooms…) |
| HostListingsScreen — liste temps réel | ✅ | Via `hostListingsStreamProvider` |
| HostListingsScreen — supprimer annonce | ✅ | Avec dialog de confirmation |
| HostListingsScreen — éditer annonce | ✅ | Route `/host/listing/:id/edit` + `CreateListingScreen` |
| HostCalendarScreen — persistance | ✅ | Sauvegarde/chargement `hostAvailability/{hostId}` |
| HostBookingsScreen — liste réelle | ✅ | StreamProvider + onglets filtrants + Confirmer/Refuser |
| Navigation hôte — onglet Messages | ✅ | Route `/host/messages` dans le ShellRoute hôte |

---

## 5. MESSAGERIE

| Tâche | Statut | Notes |
|---|---|---|
| ConversationsScreen — liste | ✅ | StreamProvider Firestore (`arrayContains: userId`) |
| ChatScreen — interface | ✅ | |
| Messagerie temps réel (Firestore) | ✅ | Stream `msgs/` + écriture réelle + `lastMessage` mis à jour |
| NotificationsScreen | ✅ | StreamProvider Firestore + "Tout lire" par batch |

---

## 6. FIREBASE

| Tâche | Statut | Notes |
|---|---|---|
| Firebase Core initialisé | ✅ | |
| `firebase_options.dart` configuré | ✅ | |
| `google-services.json` Android | ✅ | |
| Firestore — règles de sécurité | ✅ | `firestore.rules` |
| Firestore — indexes | ✅ | `firestore.indexes.json` |
| **Firebase Storage — activé** | 🔧 | À activer dans Firebase Console (région `europe-west1`) |
| Storage — règles de sécurité | ✅ | `storage.rules` déployées |
| Storage — `firebase.json` configuré | ✅ | Bucket `casaimo.firebasestorage.app` |
| FCM push notifications | ❌ | Package installé, intégration à faire |
| Crashlytics | ✅ | Package installé |

**Actions requises :**
- [ ] Firebase Console → Storage → Activer (choisir région `europe-west1`)
- [ ] `firebase deploy --only storage`

---

## 7. PAIEMENT

| Tâche | Statut | Notes |
|---|---|---|
| UI flow paiement (3 étapes) | ✅ | |
| Sélection méthode (MTN, Orange, Wave…) | ✅ | UI uniquement |
| Intégration SDK CinetPay / Flutterwave | ❌ | À intégrer en Phase 2 |
| Confirmation et reçu | ✅ | Affiche l'ID Firestore réel de la réservation |

---

## 8. ASSETS & MÉDIAS

| Tâche | Statut | Notes |
|---|---|---|
| Logo `logo1.png` | ✅ | Utilisé partout |
| Vidéo splash `assets/animations/splash.mp4` | ✅ | 5s · 1080×1920 · 30fps · 1.35 MB |
| Script Python `scripts/generate_splash.py` | ✅ | Régénérable avec `python scripts/generate_splash.py` |
| Polices Poppins | ✅ | Via Google Fonts (embedded) |

---

## 9. BUILD & DÉPLOIEMENT


## PROCHAINES PRIORITÉS (dans l'ordre)

### 🔴 Critique (bloquant)
1. **Firebase Console** — Activer Storage (région `europe-west1`)
2. **Firebase Console** — Activer Email/Password + Google + Téléphone
3. **Firebase Console** — Ajouter SHA-1 et SHA-256 pour Google Sign-In Android
4. **Google Maps** — Ajouter clé API dans `AndroidManifest.xml`
5. **Paiement Mobile Money** — Intégrer CinetPay ou Flutterwave (Phase 2)

### 🟡 Améliorations (Phase 3)
6. Notifications push FCM
7. KYC — vérification d'identité
8. Avis et notes post-séjour
9. Build APK release + Play Store

---

## BUGS CONNUS ET RÉSOLUS

| Bug | Solution |
|---|---|
| Overflow `RoleSelectionScreen` sur petits écrans | Remplacé `Spacer` par `Expanded(SingleChildScrollView)` |
| Écran rouge au clic "Voir plus d'offres" (navigateur erreur) | Fix router : exclusion `/host-profile` de la protection hôte |
| Upload Firebase Storage refusé (403) | Création et déploiement de `storage.rules` |
| Bucket Firebase Storage incorrect | Corrigé : `casaimo.firebasestorage.app` (pas `.appspot.com`) |
| `RadioListTile` déprécié Flutter 3.32+ | Remplacé par `GestureDetector` custom |
| `unnecessary_underscores` lint (`_, __`) | Remplacé par noms explicites |
| BookingScreen branché sur données mock | `listingByIdProvider` Firestore + vraie écriture `bookings/` |
| Messagerie entièrement RAM (perdue au pop) | Stream Firestore `msgs/` + écriture réelle |
| BookingHistoryScreen toujours vide | `StreamProvider` query `bookings` par `guestId` |
| HostDashboard KPIs hardcodés `'0'` | Comptage Firestore réel (listings + réservations) |
| HostCalendar "Sauvegarder" no-op | Sauvegarde/chargement `hostAvailability/{hostId}` |
| Host messages nav → ShellRoute client | `/host/messages` dans le ShellRoute hôte |
| "Mot de passe oublié" no-op | Dialog + `sendPasswordResetEmail()` Firebase |
| OTP `+229` hardcodé | Validation `startsWith('+')`, hint multi-pays |
| CreateListingScreen mode édition vide | `initState` charge listing + `update()` si edit |
| HostBookingsScreen toujours vide | `StreamProvider` + onglets par statut + Confirmer/Refuser |
| NotificationsScreen données statiques | `StreamProvider` Firestore + "Tout lire" batch |
| "Modifier profil" hôte no-op | Dialog Firestore + `refreshUser()` |
| `ListingModel.copyWith` champs manquants | 19 champs ajoutés (address, city, bedrooms…) |
| Cache Gradle 8.14 corrompu (`metadata.bin`) | Suppression cache + passage `-all` → `-bin.zip` |
| Cache `.cxx` jni corrompu | Suppression `jni-1.0.0/android/.cxx` |
| Fichier orphelin `signup_screen.dart` | Supprimé |

---

## NOTES TECHNIQUES

- **Dénormalisation Firestore** : les champs `hostPhone`, `hostEmail`, `hostBusinessType`, `hostBusinessAddress`, `hostIsVerified` sont copiés dans chaque document `listing` à la publication. Évite une requête supplémentaire à l'affichage.
- **Splash MP4** : généré via `opencv-python` + Pillow (Python). Ne nécessite pas MoviePy ni ffmpeg externe.
- **`video_player`** : le splash lit `assets/animations/splash.mp4` et navigue automatiquement à la fin de la vidéo.
- **Wildcard routes** : `/host-profile/:hostId` est accessible aux clients (exclusion explicite dans le redirect go_router).
- **Gradle** : utilise `gradle-8.14-bin.zip` (pas `-all`) pour éviter le téléchargement des sources (~200MB).
- **NDK** : versions 27 et 28 installées. CMake 3.22.1 présent dans le SDK Android.
- **`jni` 1.0.0** : dépendance transitive de `path_provider_android 2.3.1`. Nécessite CMake + NDK pour le code natif.
