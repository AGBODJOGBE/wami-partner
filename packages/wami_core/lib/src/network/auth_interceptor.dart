import 'package:dio/dio.dart';

/// Ajoute le jeton d'accès aux requêtes et signale une session expirée.
///
/// Le stockage du jeton (flutter_secure_storage, plugin natif) reste dans
/// chaque app : le socle ne fait que porter le jeton en mémoire.
class AuthInterceptor extends Interceptor {
  String? _accessToken;

  /// Appelé quand le serveur refuse un jeton qui était bien envoyé
  /// (expiré, révoqué, ou session ouverte sur un autre appareil).
  void Function()? onSessionExpired;

  String? get token => _accessToken;

  void updateToken(String? token) => _accessToken = token;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_accessToken != null && err.response?.statusCode == 401) {
      onSessionExpired?.call();
    }
    handler.next(err);
  }
}
