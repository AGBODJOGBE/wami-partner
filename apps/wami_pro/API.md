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

## Points à régler côté backend (relevés pendant l'intégration)

- `PATCH /api/driver/rides/:id/reject` : 401 permanent (voir ci-dessus).
- `PATCH /api/drivers/status` : les refus métier (véhicule non vérifié…) sortent en 500.
- Le profil n'expose ni `isApproved` ni `driverType` ni le statut des documents.
- Le socket n'applique ni la liste noire ni la session unique ; `ride:join` n'a aucun contrôle de propriété.
- Aucun événement socket pour offre expirée, suspension ou mise hors ligne forcée.
- Aucune route « mes retraits » ni « ma dette de commission » côté chauffeur.
- `GET /api/notifications` accepte `recipientId` d'un autre utilisateur.
