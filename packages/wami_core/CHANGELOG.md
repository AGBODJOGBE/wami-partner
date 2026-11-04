# Changelog — wami_core

Chaque version publiée porte un tag git `core-vX.Y.Z`.

## 0.2.0

- `ApiClient` : `patch`, `delete`, envois `multipart` (`postForm`, `patchForm`), option `unwrapEnvelope`
  (enveloppe `{success, data}`), lecture des trois formes d'erreur du serveur (message affichable).
- `AuthInterceptor` : `token` et rappel `onSessionExpired` sur 401 quand un jeton était envoyé.
- `WamiTextField.obscureText` (mot de passe).
- Toujours en pur Dart : aucune nouvelle dépendance.

## 0.1.0

- Design system WAMI : couleurs, typographie (Unbounded, DM Sans), tokens, thème sombre et clair.
- Widgets : écrans, cartes en verre, boutons, sélecteurs, champs, feuilles, barre d'onglets, KPI, graphique en barres, saisie de code.
- Réseau : `ApiClient` (dio), `AuthInterceptor`.
- Erreurs : exceptions de la couche data, `Failure`, `Result`, `guard()`.
- Configuration : `AppConfig` (`WAMI_FAKE_BACKEND`, `WAMI_API_URL`), `FakeBackend`, localisateur `sl`.
