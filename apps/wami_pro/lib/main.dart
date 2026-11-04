import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'app/config/pro_config.dart';
import 'app/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Backend local par défaut ; production : --dart-define=WAMI_API_URL=https://api.wami.bj
  await configureDependencies(proConfigFromEnvironment());
  runApp(const WamiProApp());
}
