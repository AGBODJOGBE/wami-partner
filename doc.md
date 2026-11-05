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

---

# Partie B — Routes à développer, vue par vue

Chaque ligne indique ce que **l'écran de l'app fait aujourd'hui** (souvent un contournement) et la **route à développer ou corriger** pour le remplacer. Les corps et réponses sont des **propositions** : adaptez-les, mais dites-moi la forme finale pour que je mette l'app à jour.

Priorité : **P1** bloque ou fausse l'app · **P2** améliore nettement · **P3** confort.

## B1. Inscription, connexion, validation du dossier
| P | Besoin de l'écran | Route à développer / corriger |
|---|---|---|
| P1 | L'app déduit « dossier envoyé / vérifié / véhicule contrôlé » en lisant tous les documents et le véhicule | `GET /api/drivers/me/onboarding` → `{isApproved, status, canGoOnline, blockers:[{code,message}], documents:[{type,status,rejectionReason,expiresAt}], vehicle:{id,status,isVerified}}` |
| P1 | Motif de refus d'un document (l'app affiche un texte générique) | Inclure `rejectionReason` dans `GET /api/documents/my-documents` |
| P1 | Profil sans `isApproved`, `driverType`, `profilePhotoUrl` | Les ajouter à `GET /api/drivers/profile` |
| P2 | Déconnexion : l'app efface seulement le jeton localement | `POST /api/drivers/logout` : met le jeton en liste noire, ferme la session, efface le jeton FCM |
| P2 | Étape « Soumettre mon dossier » (l'app ne fait rien) | `POST /api/drivers/me/submit-review` (passe le dossier en revue, notifie l'admin) — facultatif |
| P3 | Étape « Formation en ligne » (l'app la considère faite) | `GET /api/drivers/me/training` + `POST /api/drivers/me/training/complete` — ou retirer l'étape |
| P3 | Jeton de 365 jours sans renouvellement | `POST /api/drivers/token/refresh` |
| P3 | Cadence du battement de présence non documentée | Documenter : expire à 90 s, l'app envoie toutes les 30 s |

## B2. Accueil Missions (en ligne, propositions)
| P | Besoin de l'écran | Route à développer / corriger |
|---|---|---|
| P1 | Refuser une proposition de course (401 permanent) | Corriger `PATCH /api/driver/rides/:id/reject` (voir 2.1) |
| P1 | Refuser une proposition de livraison (n'existe pas) | `PATCH /api/driver/delivery/:id/reject` `{reason?}` |
| P1 | Passage en ligne refusé en 500 | Corriger (voir 2.2) : 403 avec `code` stable |
| P2 | Proposition de course : nom et note du client, coordonnées de destination | Enrichir `ride:new_request` : `passenger:{firstName,rating}`, `dropoff:{latitude,longitude,address}` |
| P2 | Proposition de livraison : taille du colis, fragile, paiement | Enrichir `delivery_b2c:new_request` : `parcel:{type,fragile}`, `cashToCollect` si contre-remboursement |
| P2 | L'app suppose 30 s pour répondre | Envoyer `expiresInSeconds` dans les deux événements de proposition |
| P2 | L'app ne sait pas qu'une offre a expiré | Événement `ride:request_expired` / `delivery_b2c:request_expired` `{rideId\|orderId}` |
| P2 | Suspension ou mise hors ligne forcée inconnues | Événements `driver:suspended` `{reason}` et `driver:forced_offline` `{reason}` |
| P3 | Reprise des offres après coupure | `GET /api/driver/offers/pending` (course + livraison) |
| P3 | Zones de forte demande : l'app affiche « à 1,2 km » | Ajouter `label` (quartier) à chaque cellule de `driver:density:update` |

## B3. Mission en cours (course)
| P | Besoin de l'écran | Route à développer / corriger |
|---|---|---|
| P1 | Règles d'attente et de pause : l'app utilise des valeurs par défaut (2 min gratuites, 50 FCFA/min, 15 % de commission) | `GET /api/driver/fare-policy` → `{freeWaitingSeconds, waitingRatePerMinute, pauseBilled, pauseRatePerMinute, commissionRate, noShowCancelSeconds}` |
| P2 | Navigation vers départ et destination | Coordonnées de départ et d'arrivée dans `GET /api/driver/rides/:id` et dans la réponse d'`accept` |
| P2 | Bouton **Urgence** (non branché) | `POST /api/driver/rides/:id/sos` `{latitude,longitude}` : alerte le support et l'admin |
| P2 | Appel masqué (l'app appelle le numéro réel) | `POST /api/driver/rides/:id/call-session` → numéro relais temporaire — facultatif |
| P2 | Temps réel du client absent | Écouter `ride:no_show_ready` est prévu ; documenter le payload dans le swagger |
| P3 | Fil de chat | Renvoyer `chatThreadId` dans `GET /api/driver/rides/:id` et dans la réponse d'`accept` (l'app le déduit : `ride:{id}`) |
| P3 | `accept` ignore la position du chauffeur | Accepter `driverLat/driverLng` (documentés mais ignorés) pour un ETA exact |

## B4. Livraison
| P | Besoin de l'écran | Route à développer / corriger |
|---|---|---|
| P1 | `GET /api/driver/delivery` renvoie tout, sans filtre | Ajouter `?status=active\|history&page=&limit=` et vérifier que `data` est un tableau |
| P2 | Encaissement au destinataire (espèces ou Mobile Money) | Autoriser `MOBILE_MONEY` et le contre-remboursement (`cashToCollect`) en B2C, ou confirmer que c'est hors périmètre |
| P2 | Livraison d'un autre chauffeur → 500 | Renvoyer 403 typé (voir 4.4) |
| P2 | Motif d'échec non validé | Rendre `reason` obligatoire (min. 3 caractères) sur `pickup-failure` et `delivery-failure` |
| P2 | Après `PICKUP_FAILED`, aucune reprise possible | Route `PATCH …/retry-pickup` ou documenter qu'on annule |
| P3 | Repas (restaurants) : l'app a un type « repas » | Aucun module côté chauffeur : confirmer s'il est prévu |

## B5. Gains et portefeuille
| P | Besoin de l'écran | Route à développer / corriger |
|---|---|---|
| P1 | Gains par période (l'app recalcule depuis 10 pages de transactions) | `GET /api/drivers/earnings?period=day\|week\|month` → `{rangeLabel,total,previousTotal,bars:[{label,amount}],lines:[{label,amount}]}` |
| P1 | Dette de commission sur les espèces (solde négatif) | `GET /api/drivers/commission-debt` → `{amount, since, rides:[…]}` |
| P2 | Liste de « mes retraits » (statut, motif d'échec) | `GET /api/wallets/:id/withdrawals?page=` |
| P2 | Minimum, frais et délai de retrait (l'app code 1 000 FCFA en dur) | `GET /api/wallets/config` → `{minWithdrawMobileMoney, minWithdrawBank, withdrawFee, transferFee, minTransfer, p2pEnabled}` |
| P2 | Vérification de solde avant transfert | Corriger `GET /balance/check` : comparer `mainBalance` pour un wallet EARNINGS |
| P3 | Pourboires (ligne « Pourboires » dans la maquette) | Type de transaction `TIP` côté chauffeur — ou retirer la ligne |
| P3 | Plafonds de pagination des transactions | Documenter `limit` maximum |

## B6. Performance
| P | Besoin de l'écran | Route à développer / corriger |
|---|---|---|
| P2 | Note, acceptation, annulation, niveau, objectif | `GET /api/drivers/performance` → `{rating, acceptanceRate, cancellationRate, level, nextLevelHint, goal:{target,done,bonus}}` (aujourd'hui : `stats` + bonus d'activité) |
| P3 | « Ce que disent les clients » (tags) et dernier avis | Ajouter `tags:{label:count}` et `lastReview` (aujourd'hui vides) |
| P3 | Unité des taux incohérente (0,92 ou 92) | Toujours une fraction 0–1 |

## B7. Compte, profil, préférences
| P | Besoin de l'écran | Route à développer / corriger |
|---|---|---|
| P1 | Préférences de missions (livraisons, espèces, courses longues) : le serveur n'en a pas, elles restent locales et **n'influencent pas la répartition** | `GET/PUT /api/drivers/preferences` `{acceptDeliveries, acceptCash, longTrips}` pris en compte par le matching |
| P2 | Modifier le profil en un seul appel | `PATCH /api/drivers/profile` (nom, adresse, genre, photo) au lieu de routes `/api/users/:userId/*` |
| P2 | Photo de profil | Réutiliser `POST /api/documents/upload` (`PROFILE_PHOTO`) et renvoyer `profilePhotoUrl` dans le profil |
| P2 | Suppression de compte | Ajouter les gardes (course active, solde, dette) — voir 1.4 |
| P3 | Ligne « Assistance partenaires » | `GET /api/app-config/support` → `{phone, whatsapp, email, hours}` |

## B8. Véhicules
| P | Besoin de l'écran | Route à développer / corriger |
|---|---|---|
| P2 | Demande de catégorie supérieure | Enregistrer la demande + notifier l'admin ; ajouter `GET /api/vehicles/:id/upgrade-requests` (statut) |
| P2 | Catégorie vérifiée dans la liste | Ajouter `verifiedCategory` à `my-vehicles` |
| P3 | Changement de véhicule actif | Documenter les erreurs en 400 (famille B) ou passer en famille A |

## B9. Historique
| P | Besoin de l'écran | Route à développer / corriger |
|---|---|---|
| P1 | Liste sans pagination ni filtre | `GET /api/drivers/rides?status=&from=&to=&page=&limit=` → `{rides,total,page,totalPages}` |
| P2 | Détail d'une course (reçu) | `GET /api/drivers/rides/:id` ou réutiliser `GET /api/driver/rides/:id` pour les courses terminées |
| P3 | Détail d'une livraison | Déjà `GET /api/driver/delivery/:id` ; ajouter les photos signées |

## B10. Trajets interurbains et quotidiens
| P | Besoin de l'écran | Route à développer / corriger |
|---|---|---|
| P1 | Lister **mes** trajets (l'app les retient en local) | `GET /api/driver/offers?status=` et `GET /api/driver/daily-routes?status=` |
| P2 | Détail et réservations d'un trajet | `GET /api/driver/offers/:id` → réservations confirmées (nom, places) |
| P2 | Identifier le passager d'un trajet quotidien | `GET /api/driver/passengers/lookup?phone=` → `{passengerId,name}` (aujourd'hui l'app demande un identifiant brut) |
| P2 | Motif par défaut de l'annulation d'un trajet quotidien | Corriger (voir 2.4) |

## B11. Adresses et cartes (course directe, trajets)
| P | Besoin de l'écran | Route à développer / corriger |
|---|---|---|
| P1 | Choisir une destination (aujourd'hui : liste de 25 lieux approximatifs) | `GET /api/geo/search?q=&lat=&lng=` → `[{label,city,latitude,longitude}]` et `GET /api/geo/reverse?lat=&lng=` — ou me dire quel service externe utiliser |
| P3 | Itinéraire (la carte est un décor) | `GET /api/geo/route?from=&to=` (OSRM est déjà dans la stack) |

## B12. Notifications et push
| P | Besoin de l'écran | Route à développer / corriger |
|---|---|---|
| P1 | Faille IDOR | Voir 1.1 |
| P2 | Tout marquer comme lu | `PATCH /api/notifications/read-all` |
| P2 | Pastille « non lues » | `GET /api/notifications/unread-count` |
| P2 | Ouvrir le bon écran depuis une push | Standardiser `data` : `{type, entityId, screen}` (types : offre, rappel de course programmée, retrait, document expiré, contrat) |
| P3 | Jeton FCM à l'effacement | Déjà `PATCH /fcm-token` avec `null` ; ajouter la réponse au format famille A |

## B13. Parrainage
| P | Besoin de l'écran | Route à développer / corriger |
|---|---|---|
| P1 | `apply` échoue pour un chauffeur | Corriger (voir 2.3) |
| P3 | Lien ou message de partage | `GET /api/drivers/referrals/share` → texte et lien prêts à partager |

## B14. Contrat de véhicule, bonus
| P | Besoin de l'écran | Route à développer / corriger |
|---|---|---|
| P3 | Pas de contrat → l'app interprète une erreur 4xx comme « aucun contrat » | Renvoyer `200 {data:null}` plutôt qu'une erreur |
| P3 | `vehicleCategory` de `bonus/activity/progress` | Documenter s'il est facultatif (l'app ne l'envoie pas) |

## B15. Chat
| P | Besoin de l'écran | Route à développer / corriger |
|---|---|---|
| P3 | Historique avant ouverture du socket, ou indicateur de messages non lus | `GET /api/driver/rides/:id/chat/unread` — facultatif (le temps réel suffit) |

---

## Décisions à prendre avant de coder

1. **Formes d'erreur** : une seule (famille A) — c'est la décision qui facilite le plus l'app.
2. **Préfixe** : garder `/api/driver` et `/api/drivers`, ou unifier ? (L'app suit le choix.)
3. **Service de géocodage** : externe (Google, Nominatim, Mapbox) ou route `/api/geo/*` ?
4. **Repas / restaurants** côté chauffeur : prévus ou retirés de l'app ?
5. **Mobile Money en livraison** : prévu ou non ?
6. **Pourboires** : prévus ou non ?

Quand une route est livrée, dites-moi sa forme finale : je retire le contournement correspondant dans l'app.
