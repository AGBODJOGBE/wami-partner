# WAMI Pro — routes du backend utilisées

Source : dépôt `wami-co` (Express, préfixe `/api`, pas de `/v1`). `WAMI_API_URL` est l’hôte **sans** `/api`
(le socket se connecte au même hôte). Les succès sont enveloppés dans `{success, data}` (déballé par `ApiClient`).

| Écran / feature | Route | Notes |
|---|---|---|
| Inscription | `POST /api/drivers/send-otp` → `verify-otp` (6 chiffres) → `register` (multipart) → `login` | Numéro en `+229…`. Le véhicule est exigé à la création. Mot de passe : 8 car., maj, min, chiffre |
| Connexion | `POST /api/drivers/login` | Jeton 365 j, **sans refresh** ; une connexion sur un autre appareil invalide l'ancien (`SESSION_EXPIRED`) |
| Mot de passe | `POST /api/drivers/password/forgot` · `password/reset` · `PUT /api/drivers/password` | |
| Session au démarrage | `GET /api/drivers/me/verify-token` | |
| Documents | `POST /api/documents/upload` (multipart) · `GET /api/documents/my-documents` · `DELETE /api/documents/:id` | Pièces du chauffeur (`ownerType=DRIVER`) et du véhicule (carte grise, assurance : `ownerType=VEHICLE&vehicleId=`). Doublon refusé : l'app remplace une pièce en attente/refusée |
| Validation du dossier | lue dans le statut des documents + `GET /api/drivers/vehicle` (`isVerified`) | Le serveur n'expose pas « approuvé » ; pas d'étape « soumettre » ni de formation (considérée faite) |
| En ligne / hors ligne | `PATCH /api/drivers/status` (lat/lng obligatoires) | Refus métier en 500 avec un message : affiché tel quel |
| Présence | socket `driver:heartbeat` toutes les 30 s (expire à 90 s) | |
| Propositions | socket `ride:new_request`, `delivery_b2c:new_request` | Pas de route de liste ; ni nom ni note du client ; délai ≈ 30 s |
| Refuser | — | La route de refus des courses répond 401 en permanence (lit `req.user.driverId`, absent) : refus local, le serveur passe au suivant. Pas de refus côté livraison |
| Course | `PATCH /api/driver/rides/:id/accept` (`vehicleId`) · `arrived` · `start` · `pause` · `resume` · `complete` (distance et durée réelles obligatoires) · `GET …/:id` · `POST …/rating` · `GET …/current` | **Pas de code client au départ.** Distance suivie par GPS (`ride:gps` toutes les 3 s) |
| Livraison B2C | `PATCH /api/driver/delivery/:id/accept` · `pickup-arrival` · `pickup-photo` (multipart `photo`) · `delivery-arrival` · `validate-otp` (6 chiffres) · `delivery-photo` (photo + `finalPrice`) · `GET /api/driver/delivery[/:id]` | Paiement `CASH` ou `WALLET` seulement ; pas de MoMo ni de contre-remboursement |
| Annulation par le client | socket `ride:cancelled` | |
| Gains / portefeuille | `GET /api/wallets/:walletId/balance` · `transactions` · `POST …/withdraw` | Gains par période calculés depuis les transactions. Solde principal négatif = commission due sur les espèces |
| Performance | `GET /api/drivers/stats` + `GET /api/driver/bonus/activity/progress` | |
| Bonus (nouveau) | `GET /api/driver/bonus/{activity,milestone,quality}/progress` · `POST /api/wallets/:id/consolidate` | Le bonus se transfère vers le solde principal avant retrait |
| Contrat (nouveau) | `GET /api/driver/contract` · `/installments` · `/status` | Pas de contrat → écran vide |
| Notifications (nouveau) | `GET /api/notifications` · `PATCH /api/notifications/:id/read` | `recipientId` jamais envoyé |
| Compte | `GET /api/drivers/profile` · `GET /api/drivers/vehicle` | Préférences de missions : locales seulement (le serveur n'en a pas) |

## Ajouts : routes restantes du chauffeur et de la livraison

| Écran / feature | Route | Notes |
|---|---|---|
| Annuler une mission | `DELETE /api/driver/rides/:id` (en route, arrivé ou en pause) · `DELETE /api/driver/delivery/:id` (avant la collecte) | Course en cours (`IN_PROGRESS`) non annulable |
| Client absent | `PATCH /api/driver/rides/:id/no-show` | Trop tôt : `NO_SHOW_NOT_YET_ELIGIBLE` avec le temps restant (message affiché) |
| Échec de livraison | `PATCH …/delivery/:id/pickup-failure` · `delivery-failure` · `start-return` · `complete-return` | Motif libre, toujours envoyé ; l'échec de remise passe d'abord par `delivery-arrival` |
| Changement de destination | socket `ride:destination_change_request` → `PATCH …/destination-change/accept` ou `reject` | 60 s pour répondre |
| Course directe | `POST /api/driver/rides/pickup/estimate` · `POST /api/driver/rides/pickup` | Espèces seulement. Destination choisie dans une liste de lieux approximatifs (voir ci-dessous) |
| Zones de forte demande | socket `driver:density:subscribe` → `driver:density:update` | Cellule de ~1 km la plus dense, affichée comme « à X km » ; réabonnement après `driver:density:reset` |
| Chat | socket `chat:join` / `send` / `read` + `chat:history` / `message` / `closed` / `error` | Fil `ride:{id}` ou `b2c-order:{id}` ; la salle doit avoir été rejointe (fait à l'acceptation) |
| Historique | `GET /api/drivers/rides` · `GET /api/driver/delivery` | Sans pagination côté serveur |
| Véhicules | `GET /api/vehicles/driver/my-vehicles` · `POST /api/vehicles/driver/add` (multipart) · `PATCH /api/drivers/active-vehicle` · `PATCH /api/vehicles/:id/active-categories` · `POST /api/vehicles/:id/upgrade-request` · `DELETE /api/vehicles/:id` | 5 véhicules au plus ; la demande de catégorie supérieure n'est pas enregistrée côté serveur (accusé de réception) |
| Parrainage | `GET /api/drivers/referrals` · `my-pending` · `POST …/apply` · `validate` · code à l'inscription (`usedReferralCode`) | `apply` échoue probablement pour un chauffeur (voir ci-dessous) |
| Profil | `PATCH /api/users/:userId/name\|address\|email\|phone\|…` · `POST …/verify-email\|verify-phone` · `DELETE /api/drivers/profile` | `:id` = **userId** |
| Envoyer de l'argent | `GET /api/wallets/:id/balance/check` · `POST /api/wallets/:id/transfer` | Seul le solde principal est envoyable ; le contrôle du serveur compte aussi le bonus, l'app le recoupe |
| Trajets interurbains / quotidiens | `POST/PATCH/DELETE /api/driver/offers*` · `/api/driver/daily-routes*` | **Aucune route de liste** : l'app garde les identifiants sur l'appareil |
| Push | `PATCH /api/drivers/fcm-token` | Nécessite les fichiers Firebase du projet |
| Mise à jour forcée | `GET /api/app-config/check-version?appType=DRIVER` | |

Non repris, faute d'usage côté chauffeur : `/api/documents/signed-url` (les URL signées arrivent déjà dans `my-documents`),
`/api/driver/rides/:id/reject` (cassée, voir plus bas), `ride:near:dropoff` et `ride:no_show_ready` (l'app s'appuie sur la réponse du serveur à `no-show`).

## Points à régler côté backend (relevés pendant l'intégration)

- `PATCH /api/driver/rides/:id/reject` : 401 permanent (voir ci-dessus).
- `PATCH /api/drivers/status` : les refus métier (véhicule non vérifié…) sortent en 500.
- Le profil n'expose ni `isApproved` ni `driverType` ni le statut des documents.
- Le socket n'applique ni la liste noire ni la session unique ; `ride:join` n'a aucun contrôle de propriété.
- Aucun événement socket pour offre expirée, suspension ou mise hors ligne forcée.
- Aucune route « mes retraits » ni « ma dette de commission » côté chauffeur.
- `GET /api/notifications` accepte `recipientId` d'un autre utilisateur.
- `POST /api/drivers/referrals/apply` : le contrôleur envoie le type `DRIVER` (invalide, attendu `DRIVER_STANDARD`, etc.) ; le code ne passe qu'à l'inscription.
- `POST /api/vehicles/:id/upgrade-request` n'enregistre rien (« phase 2 »).
- `GET /balance/check` compare le solde total (bonus compris) alors qu'un transfert ne débite que le solde principal.
- Aucune route pour lister les trajets interurbains / quotidiens du chauffeur.
- Le swagger annonce `ride:destination_change_requested` ; le code émet `ride:destination_change_request`.
- Les routes de documents refusent un doublon (409) sans remplacement par le chauffeur ; une pièce validée ne peut être remplacée que par un admin.
- Un `new Error('Unauthorized')` (livraison d'un autre chauffeur) sort en 500 générique.
