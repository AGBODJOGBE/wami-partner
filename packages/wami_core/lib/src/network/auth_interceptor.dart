import 'package:dio/dio.dart';

/// Ajoute le jeton d'accès aux requêtes.
///
/// À valider : stockage du jeton (flutter_secure_storage recommandé),
/// rafraîchissement (refresh token) et format d'authentification (OTP SMS ?).
class AuthInterceptor extends Interceptor {
  String? _accessToken;

  void updateToken(String? token) => _accessToken = token;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
