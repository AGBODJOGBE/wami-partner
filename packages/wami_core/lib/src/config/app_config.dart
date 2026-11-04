/// Configuration d'exécution, lue depuis les `--dart-define`.
class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.useFakeBackend,
    this.fakeLatency = const Duration(milliseconds: 450),
  });

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      apiBaseUrl: String.fromEnvironment(
        'WAMI_API_URL',
        // À valider : URL de l'API WAMI.
        defaultValue: 'https://api.wami.example',
      ),
      useFakeBackend: bool.fromEnvironment('WAMI_FAKE_BACKEND', defaultValue: true),
    );
  }

  /// Adresse de base des API REST.
  final String apiBaseUrl;

  /// `true` : les sources de données simulées remplacent les appels HTTP.
  final bool useFakeBackend;

  /// Délai artificiel des sources simulées, pour voir les états de chargement.
  final Duration fakeLatency;
}
