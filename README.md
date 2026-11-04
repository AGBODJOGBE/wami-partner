# WAMI — applications partenaires

Dépôt des deux applications partenaires de WAMI et de leur socle commun.
L'application client vit dans **son propre dépôt** et n'est pas concernée ici.

| Dossier | Contenu | Accent |
|---|---|---|
| `apps/wami_pro` | **WAMI Pro** — chauffeurs (moto, auto) et livreurs | bleu |
| `apps/wami_business` | **WAMI Business** — restaurants, hôtels, chambres, propriétaires, compagnies de bus | turquoise |
| `packages/wami_core` | Socle partagé : design system, réseau, erreurs, `Result`, widgets | — |

> ⚠️ **Code non compilé.** Il a été écrit sans SDK Flutter disponible ; seules la syntaxe,
> la résolution des imports et des symboles ont été vérifiées par script.
> Commencez par `flutter analyze` (voir plus bas) et corrigez ce qu'il signale.
>
> **WAMI Pro est branché sur le backend `wami-co`** (connexion, missions, livraisons, gains, bonus,
> contrat, notifications) : voir [`apps/wami_pro/API.md`](apps/wami_pro/API.md) pour les routes, les écarts
> et les points à régler côté serveur. WAMI Business reste sur son faux backend.

---

## Quatre règles pour durer

Vous êtes seul sur le projet : ces règles évitent qu'un changement d'une app casse l'autre
et que le socle devienne un fourre-tout.

1. **Le socle ne contient aucune logique métier.**
   `wami_core` = design system, client HTTP, erreurs, `Result`, formatage, widgets génériques.
   Une règle comme « 2 minutes d'attente gratuites » ou « pas de surbooking » vit dans
   le `domain/` de l'app concernée, jamais dans le socle.
   Test simple : si seule une app s'en sert, ça ne va pas dans `wami_core`.

2. **Le socle est versionné par tags git.**
   À chaque changement notable de `wami_core` : mettre à jour `version` dans son `pubspec.yaml`
   et `CHANGELOG.md`, puis poser un tag `core-vX.Y.Z` (ex. `git tag core-v0.2.0`).
   Les apps de ce dépôt utilisent le socle par chemin (`path:`) : elles suivent toujours la dernière version.
   Si un jour l'app client veut le socle, elle le référence **par tag**, sans être obligée de suivre :
   ```yaml
   wami_core:
     git:
       url: <url-de-ce-depot>
       path: packages/wami_core
       ref: core-v0.1.0
   ```

3. **Chaque app reste indépendante.**
   Son propre `pubspec.yaml`, ses identifiants de store, sa version, sa publication.
   Une feature n'importe jamais une autre feature ni la couche `app/` :
   les liens passent par des callbacks injectés par le routeur (`onLogout`, `onActivated`…).

4. **Aucun plugin natif dans le socle.**
   Tout ce qui est déclaré dans `packages/wami_core/pubspec.yaml` part dans **les deux** apps.
   Un paquet en pur Dart (`dio`, `equatable`…) ne coûte rien : le code inutilisé est retiré à la compilation.
   Un plugin natif (caméra, scan, cartes, localisation, notifications…) embarque son code Android/iOS
   et ses permissions dans les deux apps, même celle qui ne s'en sert pas.
   - Une seule app en a besoin → `apps/<app>/pubspec.yaml`, code dans sa feature.
   - Les deux en ont besoin avec du code commun → un paquet dédié (`packages/wami_maps`…),
     déclaré uniquement par les apps concernées.
   - Le script `tool/check_core_deps.sh` refuse tout paquet du socle absent de sa liste autorisée ;
     il tourne automatiquement sur GitHub (`.github/workflows/core-guard.yml`) à chaque modification
     du `pubspec.yaml` du socle.

---

## Permissions et stores

Objectif : chaque app ne demande **que** ses propres permissions, pour qu'aucune ne soit
bloquée à la revue Google Play ou App Store à cause de l'autre.

**Où elles sont déclarées** : uniquement dans chaque app, jamais dans le socle.

| | Android | iOS |
|---|---|---|
| WAMI Pro | `apps/wami_pro/android/app/src/main/AndroidManifest.xml` | `apps/wami_pro/ios/Runner/Info.plist` |
| WAMI Business | `apps/wami_business/android/app/src/main/AndroidManifest.xml` | `apps/wami_business/ios/Runner/Info.plist` |

**Permissions prévues** (à valider au moment d'ajouter les plugins) :

| Permission | Pro | Business | Pourquoi |
|---|---|---|---|
| Localisation au premier plan | oui | non | suivre la course, recevoir les offres proches |
| Localisation en arrière-plan | **oui** | non | suivi de la course écran éteint (voir ci-dessous) |
| Caméra | oui | oui | Pro : pièces, photo du colis · Business : scan des codes, photos de plats |
| Notifications | oui | oui | offres, commandes, réservations |
| Contacts, micro, SMS, stockage complet | non | non | à ne jamais ajouter sans besoin réel : motif fréquent de refus |

Appeler ou écrire au client par `tel:` / `sms:` n'exige **aucune** permission.

**Localisation en arrière-plan (Pro) — décision prise, à préparer avant la première publication**

Google Play et Apple l'acceptent pour une app de chauffeurs, à condition de la justifier :
- *Dans l'app* : un écran d'explication **avant** la demande système (« WAMI Pro utilise votre position
  même app fermée pour suivre vos courses et vous proposer des missions proches »), avec un bouton
  pour accepter et un pour refuser. Google l'exige (*prominent disclosure*).
- *Android* : demander d'abord la localisation au premier plan, puis l'arrière-plan dans un second temps ;
  déclarer `ACCESS_BACKGROUND_LOCATION`, `FOREGROUND_SERVICE` et `FOREGROUND_SERVICE_LOCATION`
  (Android 14+), service de type `location` avec une notification visible pendant la course.
- *Google Play Console* : remplir la déclaration « Autorisations de localisation » avec une courte
  vidéo montrant l'écran d'explication puis l'usage réel pendant une course.
- *iOS* : `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription`
  et `UIBackgroundModes` → `location` dans l'`Info.plist` de Pro ; expliquer l'usage dans les notes
  de revue App Store.
- Business ne déclare **aucune** de ces permissions.

**Pièges connus**
- *Android — fusion des manifestes* : chaque plugin ajoute ses permissions au manifeste final.
  Avant chaque publication, vérifiez le manifeste fusionné (Android Studio → `AndroidManifest.xml`
  → onglet *Merged Manifest*) et retirez ce qui ne sert pas :
  ```xml
  <manifest xmlns:tools="http://schemas.android.com/tools" …>
    <uses-permission android:name="android.permission.RECORD_AUDIO" tools:node="remove" />
  ```
- *iOS — textes d'usage* : toute permission utilisée doit avoir son texte (`NSCameraUsageDescription`,
  `NSLocationWhenInUseUsageDescription`…) dans l'`Info.plist` de l'app, sinon l'envoi est refusé.
  À l'inverse, n'ajoutez pas de texte pour une permission que l'app n'utilise pas.
- *iOS — `permission_handler`* : si vous l'utilisez, désactivez dans le `Podfile` **de chaque app**
  les permissions qu'elle n'utilise pas (macros `PERMISSION_…=0`), sinon Apple peut demander
  des justifications pour des API que l'app ne sert jamais.
- *Formulaires des stores* : la fiche « Sécurité des données » (Google) et les « Détails de
  confidentialité » (Apple) se remplissent **app par app**, d'après ses propres permissions.

**Avant chaque publication** : manifeste fusionné relu · `Info.plist` relu · fiche des données
à jour · `./tool/check_core_deps.sh` au vert.

---

## Architecture (identique dans les deux apps)

```
lib/
├── main.dart                 lecture de la config, injection, runApp
├── app.dart                  blocs globaux + MaterialApp.router
├── app/                      racine de composition (seule couche qui connaît toutes les features)
│   ├── di/injection.dart     get_it : sources → repositories → cas d'usage → cubits
│   ├── router/               go_router : redirections de session, onglets, pages plein écran
│   └── session/              SessionCubit : déconnecté / inscription / actif
├── shared/                   routes, accent, petits utilitaires sans dépendance de feature
└── features/<feature>/
    ├── domain/               entités, contrat du repository, cas d'usage (règles métier)
    ├── data/                 sources Api + Fake, implémentation du repository
    └── presentation/         cubits/blocs, pages, widgets
```

- Les erreurs ne traversent pas les couches sous forme d'exception : la source lève, le repository
  convertit avec `guard()` en `Result<T>` (`Ok` / `Err(Failure)`), l'UI affiche `failure.message`.
- Chaque source de données existe en deux versions : `…ApiDataSource` (HTTP, endpoints **à valider**)
  et `…FakeDataSource` (démo). Le choix se fait dans `injection.dart` selon `WAMI_FAKE_BACKEND`.

### WAMI Pro

Onglets **Missions · Gains · Compte**. Inscription (métier, véhicule, numéro, code SMS, pièces,
vérification), mise en ligne, offres avec compte à rebours, course (code client, attente facturée,
pause), livraison (check-list, photo, code de remise, espèces ou MoMo), reçu, gains, portefeuille,
performance, conformité des documents.

### WAMI Business

Onglets **Tableau · Activité · Offre · Finances · Compte**. Un compte peut gérer plusieurs
établissements ; « Activité » et « Offre » changent selon le métier de l'établissement courant :

| Métier | Activité | Offre |
|---|---|---|
| Restaurant | Commandes : nouvelles → en cuisine → prêtes (accepter avec temps de préparation, refuser avec motif, +5 min, prête) | Menu : plats épuisés, pause des commandes |
| Hôtel, chambres | Planning de la semaine, demandes à confirmer, arrivées, réservation au comptoir, check-in par code | Types de chambres : prix, chambres ouvertes |
| Maisons, appartements | Demandes de visite : accepter, refuser, proposer un créneau | Biens (loué / disponible), plages de visite |
| Compagnie de bus | Départs du jour (remplissage app / guichet, retard), plan des places partagé, embarquement par code | Lignes et prix |

Plus : avis clients avec réponse, équipe (rôles propriétaire / gérant / employé), versements.

---

## Démarrer

Prérequis : Flutter ≥ 3.27 (Dart ≥ 3.6).

Les dossiers `android/` et `ios/` ne sont pas inclus.

**WAMI Pro** : un script les génère et y déclare les permissions de Pro (localisation y compris en arrière-plan,
service de premier plan, caméra, notifications ; textes d'usage et mode arrière-plan iOS) :

```bash
./tool/setup_pro_platform.sh
```

**WAMI Business** : génération simple, sans permission de localisation :

```bash
cd apps/wami_business
flutter create --org bj.wami --project-name wami_business --platforms android,ios .
```

`flutter create .` n'écrase pas les fichiers existants (`lib/`, `pubspec.yaml`, `test/`) :
il ajoute seulement ce qui manque.
L'identifiant `bj.wami` est **à valider** (il devient l'ID de store, difficile à changer ensuite).

Puis, dans chaque app :

```bash
flutter pub get
flutter analyze
flutter test
flutter run                       # faux backend : démo complète sans serveur
flutter run                       # Pro : backend local (voir ci-dessous) ; Business : faux backend
flutter run --dart-define=WAMI_FAKE_BACKEND=true                       # Pro : démo sans serveur
flutter run --dart-define=WAMI_API_URL=https://api.exemple             # Pro : production (hôte sans /api)
```

### WAMI Pro sur le backend local

Démarrez d'abord le backend `wami-co` (MongoDB et Redis requis : `npm run docker:up`, puis `npm run dev`, port 3000).
Pro vise alors `http://10.0.2.2:3000` sur émulateur Android et `http://localhost:3000` sur simulateur iOS.
Sur un **téléphone réel**, passez l'IP de l'ordinateur : `--dart-define=WAMI_API_URL=http://192.168.1.20:3000`.
Après la mise en production, remplacez par l'URL réelle, sans `/api`. Le HTTP en clair n'est autorisé qu'en debug
(`tool/setup_pro_platform.sh`).

### Parcours de démo (faux backend)

| App | Code SMS | Autres codes |
|---|---|---|
| Pro | `123456` (inscription), connexion : tout mot de passe | code du destinataire d'une livraison : `482193` (une course ne demande aucun code) |
| Business | `1234` | check-in hôtel : `482193` · billet de bus : `300512` |

Dans Business, les pièces envoyées sont validées 3 s plus tard ; le compte de démo gère un
restaurant, un hôtel, une résidence et une compagnie de bus (touchez le nom en haut du Tableau pour changer).
Noms, chiffres et numéros sont fictifs.

---

## Git

```bash
cd wami-partenaires            # ce dossier
git init
git add .
git commit -m "Socle wami_core, WAMI Pro et WAMI Business (faux backend)"
git tag core-v0.1.0
git branch -M main
git remote add origin <url>
git push -u origin main --tags
```

Les `pubspec.lock` des apps sont versionnés, celui du socle non (voir `.gitignore`).

---

## À valider

**Back-end**
- Tous les endpoints des sources `…ApiDataSource` (chemins, champs JSON).
- Stockage et rafraîchissement du jeton (flutter_secure_storage recommandé) dans `AuthInterceptor`.
- Notifications temps réel (offres Pro, nouvelles commandes Business) : aujourd'hui en relecture
  périodique ; à remplacer par push (FCM) ou WebSocket.

**Règles métier** (valeurs actuelles dans le code, à confirmer)
- Pro : 2 min d'attente gratuites puis 50 F/min, pause 25 F/min, commission 15 %, 15 s pour accepter une offre.
- Business : commission 12 %, versement hebdomadaire, 3 min pour accepter une commande, préparation 5–90 min,
  +5 min deux fois au plus, embarquement 45 min avant le départ, prix plancher chambre 2 000 F.
- Pièces exigées à l'inscription selon le métier (RCCM, IFU…) et délai de vérification.
- Paiement au comptoir (hôtel, guichet) : soumis ou non à la commission WAMI.

**Produit**
- Ajout de plats, photos, nouvelles chambres, nouvelles lignes : dans l'app ou sur un back-office web ?
- Scan de QR code (check-in, billets) : paquet à ajouter (`mobile_scanner`).
- Localisation française des composants Material (`flutter_localizations`) : le sélecteur de date est en anglais sans elle.
- Carte réelle (Pro) : `RouteMapView` est un décor ; à remplacer par Google Maps ou Mapbox.
- Identifiants de store et nom des apps.
