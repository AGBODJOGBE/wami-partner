import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wami_core/wami_core.dart';
import 'package:wami_business/app.dart';
import 'package:wami_business/app/di/injection.dart';

void main() {
  testWidgets('sans compte, l’app ouvre l’inscription', (tester) async {
    await configureDependencies(const AppConfig(apiBaseUrl: '', useFakeBackend: true, fakeLatency: Duration.zero));
    await tester.pumpWidget(const WamiBusinessApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Recevoir le code'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
