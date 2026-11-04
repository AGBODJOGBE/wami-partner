import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Petit stockage clé → texte sur l'appareil. Sert à garder ce que le serveur ne sait pas relister
/// (trajets interurbains publiés, trajets quotidiens) : sans route de liste, l'app retient les identifiants.
class LocalStore {
  LocalStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;

  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: 'wami_pro_$key');
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: 'wami_pro_$key', value: value);
    } catch (_) {}
  }
}
