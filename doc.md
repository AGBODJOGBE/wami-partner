# Corrections à prévoir côté backend (`wami-co`)

Relevées pendant l'intégration de WAMI Pro. **Aucune n'a été appliquée par l'app** : elle contourne chacune d'elles, et ces contournements pourront être retirés une fois le backend corrigé.

Chemins relatifs à `src/`. « Lu dans le code » signifie que je n'ai pas exécuté le backend : à vérifier au test.

Légende : 🔴 sécurité ou bloquant · 🟠 manque fonctionnel · 🟡 cohérence ou documentation

---

## 🔴 1. Sécurité

### 1.1 IDOR sur `GET /api/notifications`
- **Fichier :** `modules/notification/presentation/http/controllers/GetNotificationHistoryController.ts`
- **Problème :** `const recipientId = req.query.recipientId as string || req.userId!;` — tout utilisateur authentifié lit les notifications d'un autre en passant `?recipientId=`.
- **Correction proposée :** n'accepter `recipientId` que si l'appelant est admin (`req.profileType === 'admin' && !!req.adminId`, même critère que `requireAdmin`). Sinon, utiliser `req.userId`.
- **État :** un correctif existe sur la branche `fix/notifications-recipient-idor` de `wami-co` (commit `60c9149`, 4 tests). **Non fusionné.** À reprendre ou à jeter selon votre décision.
- **Côté app :** n'envoie jamais `recipientId`.

### 1.2 Socket.io : session et propriété non contrôlées
- **Fichier :** `app.ts:945-983` (middleware `io.use`), `app.ts:1140-1144` (`ride:join`, `ride:driver:join`, `order:join`, `order:driver:join`).
- **Problèmes :**
  - Le middleware vérifie le JWT mais **pas la liste noire ni la session unique (`jti`)** : le jeton d'une session remplacée (`SESSION_EXPIRED` en HTTP) ou d'un profil supprimé ouvre quand même un socket.
  - `ride:join` / `order:join` **n'ont aucun contrôle de propriété** : n'importe quel socket authentifié peut rejoindre la salle de n'importe quelle course ou commande (position GPS, chat, adresses).
  - Un jeton sans `profileType` chauffeur n'est pas rejeté à la connexion.
- **Correction proposée :** réutiliser la logique de `authMiddleware` dans `io.use` ; vérifier dans chaque `join` que l'utilisateur est le passager ou le chauffeur de la course/commande.

### 1.3 `GET /api/documents/signed-url` sans contrôle de propriété
- **Fichier :** `modules/document/presentation/http/routes/document.routes.ts:130`
- **Problème :** accepte toute clé `private/…` sans vérifier qu'elle appartient à l'appelant : on peut obtenir l'URL signée du document d'un autre.
- **Correction proposée :** vérifier que la clé correspond à un document du demandeur (ou le retirer, car `my-documents` renvoie déjà des URL signées).

### 1.4 Suppression de compte sans garde
- **Fichier :** `modules/driver/presentation/http/controllers/DeleteDriverProfileController.ts` (`DELETE /api/drivers/profile`)
- **Problème :** aucune vérification d'une course en cours ni d'un solde de portefeuille avant désactivation.
- **Correction proposée :** refuser si une course/livraison est active ou si le solde (ou la dette de commission) est non nul ; ou prévoir un flux explicite.

### 1.5 Erreurs 500 qui exposent `error.message`
- **Où :** la plupart des contrôleurs (exemple : `GetNotificationHistoryController`) renvoient `error.message` brut.
- **Correction proposée :** message générique côté client, détail dans les logs.

---

## 🔴 2. Bugs bloquants

### 2.1 `PATCH /api/driver/rides/:rideId/reject` répond 401 en permanence
- **Fichiers :** `RejectRideController` ; `shared/presentation/http/middlewares/authMiddleware.ts:615-621` ; `modules/ride/presentation/routes/rideRoutes.ts:386-390`.
- **Problème :** le contrôleur lit `req.user.driverId`, mais le shim d'`authMiddleware` ne pose que `userId`, `profileId` et `role`. La valeur est `undefined` et la route répond 401. La route est de plus enregistrée **conditionnellement** (`if (rejectRideController)`).
- **Impact :** un 401 avec jeton déclenche la déconnexion dans l'app. **Le chauffeur ne peut donc pas refuser une course.** L'app ne l'appelle pas et laisse l'offre expirer (≈ 30 s).
- **Correction proposée :** lire `req.user.profileId` comme les autres contrôleurs de course, et enregistrer la route sans condition.
- **À vérifier à l'exécution** (déduit du code).

### 2.2 `PATCH /api/drivers/status` : refus métier renvoyés en 500
- **Fichier :** `modules/driver/presentation/http/controllers/UpdateDriverStatusController`.
- **Problème :** seuls les messages contenant « must be approved » ou « no vehicle assigned » donnent un 403. Les autres partent en **500** : « Driver must have an assigned vehicle to go online », « Suspended drivers cannot go online », « Vehicle must be verified before going online », « Vehicle is in PENDING/REJECTED/RETIRED/MAINTENANCE status… ».
- **Correction proposée :** 403 (ou 422) avec un `code` stable (`VEHICLE_NOT_VERIFIED`, `DRIVER_SUSPENDED`, `NO_VEHICLE`…).
- **Côté app :** affiche le message tel quel.

### 2.3 `POST /api/drivers/referrals/apply` échoue pour un chauffeur
- **Fichiers :** `modules/referral/presentation/http/controllers/CreateReferralController.ts:23` ; `modules/referral/domain/value-objects/ReferralType.ts:25-31`.
- **Problème :** le contrôleur passe `req.profileType.toUpperCase()` (`'DRIVER'`), valeur invalide. Les valeurs valides sont `PASSENGER`, `DRIVER_STANDARD`, `DRIVER_PREMIUM`, `DRIVER_VIP`, `PARTNER`. Réponse attendue : 422 « Invalid referral type: DRIVER ».
- **Contournement :** le code se saisit à l'inscription (`usedReferralCode`, que `RegisterDriverUseCase.ts:416-427` mappe correctement).
- **Correction proposée :** mapper le profil et la catégorie du chauffeur vers le bon `ReferralType`, comme à l'inscription.

### 2.4 `DELETE /api/driver/daily-routes/:routeId` : motif par défaut invalide
- **Fichier :** `modules/ride/presentation/routes/offerRoutes.ts:225`
- **Problème :** le serveur met `reason = ''` par défaut alors que le use case exige au moins 5 caractères : appel sans motif = échec.
- **Correction proposée :** valeur par défaut valide (« Annulé par le chauffeur ») ou 400 explicite. L'app envoie toujours un motif.

---

## 🟠 3. Données manquantes pour l'app

### 3.1 Profil chauffeur incomplet — `GET /api/drivers/profile`
Absents : `isApproved`, `driverType`, `profilePhotoUrl`, statut des documents.
→ L'app **reconstruit** la validation du dossier en lisant tous les documents + le véhicule.
→ Proposition : ajouter `isApproved`, `driverType`, `documentsStatus` (par type) et `profilePhotoUrl`.

### 3.2 Propositions de course (`ride:new_request`) pauvres
- Pas de **nom ni de note du client** ; `dropoff` n'a **que `address`** (pas de latitude/longitude).
- Conséquences : pas de navigation vers la destination, pas de distance chauffeur → arrivée, note client absente de l'écran.
- Proposition : ajouter `passenger { firstName, rating }` et `dropoff.latitude/longitude`.

### 3.3 Pas de route pour **lister** les trajets du chauffeur
- Concerne les trajets interurbains (`/api/driver/offers`) et quotidiens (`/api/driver/daily-routes`). Le seul GET est `GET /api/passenger/offers` (recherche passager).
- L'app **garde les identifiants sur l'appareil** : perdus à la réinstallation.
- Proposition : `GET /api/driver/offers` et `GET /api/driver/daily-routes` (avec statuts), et `GET …/:id`.

### 3.4 Pas de route « mes retraits » ni « ma dette de commission »
- Seuls les endpoints admin existent (`/api/admin/drivers/commission-debts`, `admin.routes.ts:729,733`).
- Un solde principal **négatif** (commission des courses en espèces) est possible : l'app l'affiche comme « commission due » sans détail.
- Proposition : `GET /api/wallets/:id/withdrawals` et une route chauffeur de dette de commission.

### 3.5 Pas de route de gains par période
- L'app recalcule jour/semaine/mois à partir de toutes les transactions (pages de 100 ; limite maximale **non documentée**).
- Proposition : `GET /api/drivers/earnings?period=day|week|month` (total, détail, comparaison à la période précédente).

### 3.6 Pas de liste des propositions en attente
- Les demandes n'arrivent que par socket ; seule la reconnexion rejoue la dernière (`isReplay`).
- Proposition : `GET /api/driver/offers/pending` (facultatif, pour fiabiliser les reprises).

### 3.7 Livraisons : pas de refus ; pas de Mobile Money ni de contre-remboursement
- Aucune route pour **refuser** une proposition de livraison.
- `paymentMethod` limité à `CASH` et `WALLET` : l'écran d'encaissement au destinataire a été retiré de l'app.

### 3.8 Événements socket manquants pour le chauffeur
Rien n'est envoyé pour : **offre expirée**, **suspension du compte**, **mise hors ligne forcée**. L'app doit deviner en relisant `GET /api/drivers/profile` et `GET /api/driver/rides/current`.
Source : `ai-docs/planning/active/contract-blocked-driver-dispatch-fix-plan.md`.

### 3.9 Pas de refresh token
Jeton de 365 jours sans renouvellement ; seule une reconnexion le remplace. Acceptable, mais sans révocation fine côté appareil.

---

## 🟡 4. Cohérence de l'API

### 4.1 Deux formes d'erreur (et une troisième)
| Famille | Où | Forme |
|---|---|---|
| A | driver, vehicles, wallet, user, delivery-b2c, referral, contract, bonus | `{success:false, error:{message, code, details?}}` |
| B | rides, offers, daily-routes, no-show, documents, `active-vehicle`, OTP | `{success:false, error:"texte"}` (+ `code`, `remainingSeconds`, `readyAt` à plat) |
| C | `PATCH /drivers/fcm-token`, `POST /wallets/:id/recharge` | `{success:false, message}` ou `{error:"…"}` |

L'app gère les trois. Proposition : une seule forme (A).

### 4.2 `/api/driver` (singulier) et `/api/drivers` (pluriel)
Auth, profil, statut, stats et historique sont sur `/api/drivers` ; courses, livraisons, bonus et contrat sur `/api/driver`. De plus, `/api/driver` est monté 5 fois avec un `authMiddleware` non borné : **toute route inconnue sous `/api/driver/*` répond 401 au lieu de 404**.

### 4.3 `error` parfois chaîne, parfois objet — voir 4.1.

### 4.4 `new Error('Unauthorized')` → 500 générique
Livraison d'un autre chauffeur : devrait être un 403 typé (`modules/delivery-b2c/…/errors.ts`).

### 4.5 Motifs d'échec de livraison non validés
`pickup-failure` / `delivery-failure` acceptent un `reason` absent sans erreur. L'app l'envoie toujours.

### 4.6 `POST /api/vehicles/:id/upgrade-request` n'enregistre rien
Simple accusé (« Phase 2 ») : la demande de catégorie supérieure est perdue.

### 4.7 `GET /api/wallets/:id/balance/check` compare le solde total
`hasSufficientFunds` inclut bonus et parrainage, alors qu'un transfert d'un wallet `EARNINGS` ne débite que `MAIN`. L'app recoupe avec `mainBalance`.

### 4.8 Documents
- Un doublon est refusé (409) ; une pièce **validée** ne peut être remplacée que par un admin. L'app supprime une pièce en attente/refusée avant de renvoyer.
- Une erreur de type MIME (multer) a un **statut HTTP non maîtrisé** (probablement 500) : à renvoyer en 400/415.

### 4.9 Pagination
`GET /api/drivers/rides` et `GET /api/driver/delivery` renvoient tout, sans pagination.

### 4.10 `login` ne vérifie pas `isApproved`
Un chauffeur non approuvé se connecte et ne découvre le blocage qu'au passage « en ligne ».

---

## 🟡 5. Documentation à aligner sur le code

| Sujet | Doc | Réalité |
|---|---|---|
| Événement changement de destination | swagger : `ride:destination_change_requested` (`rideSwagger.ts:1392`) | le code émet `ride:destination_change_request` |
| `POST /wallets/:id/transfer` | docstring : `transferId`, `recipientPhone` | réponse : `{sentAmount, feeAmount, receivedAmount, senderWalletType, recipientWalletType, effectiveTransferMode, senderRemainingBalance}` |
| `GET /wallets/:id/balance/check` | docstring : `availableBalance`, `requestedAmount` | réponse : `{hasSufficientFunds, totalBalance, mainBalance, bonusBalance, referralBalance, shortfall}` |
| `verifiedCategory` | `ai-docs/api-contract-categories-multiples-chauffeur.md` : dans la liste | absent de `my-vehicles`, présent seulement dans les PATCH et `GET /:id` |
| `wallet-full-doc.md` | 3 sous-soldes | 4 : `AFFILIATE` existe (retirable, jamais dépensable) |
| `DailyRouteStatus` | `domain/enums/DailyRouteStatus.ts` (3 valeurs) | l'entité utilise `DailyRouteOfferStatus` (`ACTIVE, PAUSED, CANCELLED, EXPIRED`) |
| `driver:heartbeat` | aucune cadence documentée | présence expirée après **90 s** ; l'app envoie toutes les 30 s |
| Pas d'`accept` avec position | doc-comment : `driverLat/driverLng` | ignorés par le contrôleur |
| Limites de pagination des transactions | non documentées | l'app suppose 100 par page |

---

## À tester à l'exécution (non vérifié)

1. Le 401 permanent de `reject` (2.1).
2. La forme exacte de `GET /api/driver/delivery` : tableau direct dans `data` (annoncé) — l'app lit `items` après déballage.
3. Le contenu de `ride:cancelled` (annoncé `{rideId, rideNumber, cancelledBy, reason, cancelledAt}`).
4. `GET /api/drivers/profile` : forme de `address` et présence de `referralCode`, `isEmailVerified`, `isPhoneVerified`, `createdAt`.
5. La réponse de `POST /api/documents/upload` pour un document de véhicule (`ownerType=VEHICLE`).
6. Les champs requis par `POST /api/drivers/register` : l'app envoie `category=STANDARD`, `isVehicleOwner=true` et `ownVehicle[...]`.
7. `PATCH /api/driver/rides/:id/accept` : l'app envoie `vehicleId`, rien d'autre.
8. Les limites de pagination de `GET /wallets/:id/transactions` (l'app demande 100, jusqu'à 10 pages).

---

## Ordre de traitement suggéré

1. 1.1 · 1.2 · 1.3 (sécurité)
2. 2.1 · 2.2 · 2.3 · 2.4 (bugs)
3. 3.1 · 3.2 · 3.3 (le plus gros gain pour l'app)
4. 3.4 · 3.5 · 3.8
5. 4.x et 5 (cohérence et documentation)
