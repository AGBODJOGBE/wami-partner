import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wami_core/wami_core.dart';

/// Identité du chauffeur renvoyée à la connexion. Le `walletId` sert aux
/// routes `/api/wallets/:walletId/...`, le `userId` aux notifications.
class DriverIdentity {
  const DriverIdentity({
    required this.token,
    required this.userId,
    required this.driverId,
    required this.walletId,
    required this.phone,
    this.firstName = '',
    this.lastName = '',
    this.driverType = 'VTC',
  });

  final String token;
  final String userId;
  final String driverId;
  final String walletId;
  final String phone;
  final String firstName;
  final String lastName;

  /// `VTC`, `DELIVERY` ou `BOTH`.
  final String driverType;

  String get fullName => '$firstName $lastName'.trim();
}

/// Conserve la session (jeton + identifiants) dans le stockage sécurisé et
/// alimente `AuthInterceptor`. Le serveur n'a pas de refresh token : le jeton
/// vit 365 jours, et une nouvelle connexion remplace l'ancien.
class SessionStore {
  SessionStore(this._auth, [FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final AuthInterceptor _auth;
  final FlutterSecureStorage _storage;
  DriverIdentity? _identity;

  /// Appelé à la déconnexion (fermeture du socket, arrêt du suivi).
  void Function()? onCleared;

  DriverIdentity? get identity => _identity;

  static const _keys = ['token', 'userId', 'driverId', 'walletId', 'phone', 'firstName', 'lastName', 'driverType'];

  Future<DriverIdentity?> restore() async {
    try {
      final v = {for (final k in _keys) k: await _storage.read(key: 'wami_pro_$k')};
      final token = v['token'];
      if (token == null || v['driverId'] == null) return null;
      return _set(DriverIdentity(
        token: token,
        userId: v['userId'] ?? '',
        driverId: v['driverId']!,
        walletId: v['walletId'] ?? '',
        phone: v['phone'] ?? '',
        firstName: v['firstName'] ?? '',
        lastName: v['lastName'] ?? '',
        driverType: v['driverType'] ?? 'VTC',
      ));
    } catch (_) {
      return null;
    }
  }

  Future<void> save(DriverIdentity id) async {
    _set(id);
    final values = {
      'token': id.token,
      'userId': id.userId,
      'driverId': id.driverId,
      'walletId': id.walletId,
      'phone': id.phone,
      'firstName': id.firstName,
      'lastName': id.lastName,
      'driverType': id.driverType,
    };
    try {
      for (final e in values.entries) {
        await _storage.write(key: 'wami_pro_${e.key}', value: e.value);
      }
    } catch (_) {
      // Stockage indisponible : la session reste valable jusqu'à la fermeture de l'app.
    }
  }

  Future<void> clear() async {
    _identity = null;
    _auth.updateToken(null);
    onCleared?.call();
    try {
      for (final k in _keys) {
        await _storage.delete(key: 'wami_pro_$k');
      }
    } catch (_) {}
  }

  DriverIdentity _set(DriverIdentity id) {
    _identity = id;
    _auth.updateToken(id.token);
    return id;
  }

  /// Identité requise par les routes protégées (wallet, notifications…).
  DriverIdentity get requireIdentity {
    final id = _identity;
    if (id == null) throw const ServerException(statusCode: 401, message: 'Session expirée. Reconnectez-vous.');
    return id;
  }
}
