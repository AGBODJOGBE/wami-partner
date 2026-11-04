import '../config/app_config.dart';

/// Outils communs aux sources de données simulées.
class FakeBackend {
  const FakeBackend(this._config);
  final AppConfig _config;

  /// Simule la latence réseau.
  Future<void> latency([double factor = 1]) {
    return Future<void>.delayed(_config.fakeLatency * factor);
  }

  /// Référence courte du type « WMI-4F7K2 ».
  String reference() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final seed = DateTime.now().microsecondsSinceEpoch;
    final buffer = StringBuffer('WMI-');
    var n = seed;
    for (var i = 0; i < 5; i++) {
      buffer.write(chars[n % chars.length]);
      n = n ~/ chars.length + 7 * i;
    }
    return buffer.toString();
  }
}
