import 'package:flutter/widgets.dart';
import 'package:wami_core/wami_core.dart';

import 'app.dart';
import 'app/di/injection.dart';

/// Lancement :
///   flutter run                                   → faux backend (démo complète)
///   flutter run --dart-define=WAMI_FAKE_BACKEND=false --dart-define=WAMI_API_URL=https://…
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies(AppConfig.fromEnvironment());
  runApp(const WamiBusinessApp());
}
