import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:wami_core/wami_core.dart';

/// Notifications push (FCM). Le jeton de l'appareil est envoyé au serveur
/// (`PATCH /api/drivers/fcm-token`) après connexion, et effacé à la déconnexion.
///
/// Sans les fichiers Firebase du projet (`google-services.json`, `GoogleService-Info.plist`),
/// l'initialisation échoue et l'app fonctionne sans push : aucune exception ne sort d'ici.
class PushService {
  PushService(this._api);
  final ApiClient _api;

  bool _ready = false;
  String? _sent;

  Future<bool> _init() async {
    if (_ready) return true;
    try {
      await Firebase.initializeApp();
      await FirebaseMessaging.instance.requestPermission();
      FirebaseMessaging.instance.onTokenRefresh.listen(_send);
      return _ready = true;
    } catch (_) {
      return false;
    }
  }

  /// À appeler une fois la session ouverte.
  Future<void> register() async {
    if (!await _init()) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _send(token);
    } catch (_) {}
  }

  Future<void> _send(String token) async {
    if (token == _sent) return;
    try {
      await _api.patch('/api/drivers/fcm-token', body: {'fcmToken': token});
      _sent = token;
    } catch (_) {}
  }

  /// À appeler avant la déconnexion, tant que le jeton de session est valide.
  Future<void> unregister() async {
    if (!_ready) return;
    try {
      await _api.patch('/api/drivers/fcm-token', body: {'fcmToken': null});
      _sent = null;
    } catch (_) {}
  }
}
