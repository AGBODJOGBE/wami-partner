# Changelog — wami_core

Chaque version publiée porte un tag git `core-vX.Y.Z`.

## 0.1.0

- Design system WAMI : couleurs, typographie (Unbounded, DM Sans), tokens, thème sombre et clair.
- Widgets : écrans, cartes en verre, boutons, sélecteurs, champs, feuilles, barre d'onglets, KPI, graphique en barres, saisie de code.
- Réseau : `ApiClient` (dio), `AuthInterceptor`.
- Erreurs : exceptions de la couche data, `Failure`, `Result`, `guard()`.
- Configuration : `AppConfig` (`WAMI_FAKE_BACKEND`, `WAMI_API_URL`), `FakeBackend`, localisateur `sl`.
