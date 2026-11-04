import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wami_core/wami_core.dart';

import 'app.dart';
import 'app/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // flutter run --dart-define=WAMI_FAKE_BACKEND=false --dart-define=WAMI_API_URL=https://api.wami.bj
  await configureDependencies(AppConfig.fromEnvironment());
  runApp(const WamiProApp());
}
