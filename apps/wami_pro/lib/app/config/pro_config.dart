import 'package:flutter/foundation.dart';
import 'package:wami_core/wami_core.dart';

/// Configuration de WAMI Pro, lue depuis les `--dart-define`.
///
/// Par défaut, l'app vise le **backend local** (`npm run dev`, port 3000) :
/// - émulateur Android : `http://10.0.2.2:3000` (l'alias de la machine hôte) ;
/// - simulateur iOS et autres : `http://localhost:3000` ;
/// - téléphone réel : donnez l'IP de votre ordinateur sur le Wi-Fi, ou l'URL de production :
///   `--dart-define=WAMI_API_URL=http://192.168.1.20:3000`
///
/// `WAMI_API_URL` est l'hôte **sans** `/api`. Pour la démo hors ligne : `--dart-define=WAMI_FAKE_BACKEND=true`.
AppConfig proConfigFromEnvironment() {
  const url = String.fromEnvironment('WAMI_API_URL');
  const fake = bool.fromEnvironment('WAMI_FAKE_BACKEND', defaultValue: false);
  return AppConfig(apiBaseUrl: url.isNotEmpty ? url : localBackendUrl(), useFakeBackend: fake);
}

String localBackendUrl() =>
    defaultTargetPlatform == TargetPlatform.android ? 'http://10.0.2.2:3000' : 'http://localhost:3000';
