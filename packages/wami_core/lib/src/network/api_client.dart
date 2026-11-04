import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../error/exceptions.dart';
import 'auth_interceptor.dart';

/// Client HTTP partagé par toutes les sources de données distantes.
/// Il ne renvoie que du JSON décodé (toujours un objet) et ne lève que des
/// exceptions de `core/error`.
///
/// - `unwrapEnvelope` : le serveur enveloppe les succès dans `{success, data}`.
///   Avec `true`, le contenu de `data` est renvoyé ; une liste devient
///   `{'items': [...]}` et le `message` de premier niveau est conservé.
/// - Les erreurs sont lues dans les trois formes du serveur :
///   `{error: {code, message}}`, `{error: "texte"}` et `{message: "texte"}`.
class ApiClient {
  ApiClient(AppConfig config, AuthInterceptor authInterceptor, {this.unwrapEnvelope = false})
      : _dio = Dio(
          BaseOptions(
            baseUrl: config.apiBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 20),
            headers: {'Accept': 'application/json', 'Accept-Language': 'fr'},
          ),
        )..interceptors.add(authInterceptor);

  final Dio _dio;
  final bool unwrapEnvelope;

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) {
    return _send(() => _dio.get<dynamic>(path, queryParameters: query));
  }

  Future<Map<String, dynamic>> post(String path, {Object? body}) {
    return _send(() => _dio.post<dynamic>(path, data: body));
  }

  Future<Map<String, dynamic>> put(String path, {Object? body}) {
    return _send(() => _dio.put<dynamic>(path, data: body));
  }

  Future<Map<String, dynamic>> patch(String path, {Object? body}) {
    return _send(() => _dio.patch<dynamic>(path, data: body));
  }

  Future<Map<String, dynamic>> delete(String path, {Object? body}) {
    return _send(() => _dio.delete<dynamic>(path, data: body));
  }

  /// Envoi `multipart/form-data` : champs texte (clés à plat, notation à
  /// crochets pour les objets imbriqués) et fichiers (`champ` → chemin local).
  Future<Map<String, dynamic>> postForm(
    String path, {
    Map<String, String> fields = const {},
    Map<String, String> files = const {},
  }) async {
    final form = await _form(fields, files);
    return _send(() => _dio.post<dynamic>(path, data: form, options: _upload));
  }

  Future<Map<String, dynamic>> patchForm(
    String path, {
    Map<String, String> fields = const {},
    Map<String, String> files = const {},
  }) async {
    final form = await _form(fields, files);
    return _send(() => _dio.patch<dynamic>(path, data: form, options: _upload));
  }

  // Les envois de photos sont plus lents que les appels JSON.
  static final _upload = Options(sendTimeout: const Duration(seconds: 60), receiveTimeout: const Duration(seconds: 60));

  Future<FormData> _form(Map<String, String> fields, Map<String, String> files) async {
    final form = FormData.fromMap(fields);
    for (final e in files.entries) {
      form.files.add(MapEntry(e.key, await MultipartFile.fromFile(e.value)));
    }
    return form;
  }

  Future<Map<String, dynamic>> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      return _decode(response.data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Map<String, dynamic> _decode(Object? body) {
    if (body is! Map) return body is List ? {'items': body} : <String, dynamic>{};
    final map = Map<String, dynamic>.from(body);
    if (!unwrapEnvelope || !map.containsKey('data')) return map;
    final data = map['data'];
    final message = map['message'];
    final inner = switch (data) {
      Map() => Map<String, dynamic>.from(data),
      List() => <String, dynamic>{'items': data},
      _ => <String, dynamic>{},
    };
    if (message is String) inner.putIfAbsent('message', () => message);
    return inner;
  }

  Exception _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const NetworkException();
      default:
        final status = e.response?.statusCode;
        final data = e.response?.data;
        if (data is Map) {
          final err = data['error'];
          String? code;
          String? message;
          if (err is Map) {
            code = err['code'] as String?;
            message = err['message'] as String?;
            final details = err['details'];
            if (details is Map && details.isNotEmpty) message = '${details.values.first}';
          } else {
            code = data['code'] as String?;
            message = err is String ? err : data['message'] as String?;
          }
          if (status != null && status >= 400 && status < 500 && (code != null || message != null)) {
            return BusinessRuleException(code ?? 'rejected', message);
          }
          if (message != null) return ServerException(statusCode: status, message: message);
        }
        return ServerException(statusCode: status, message: e.message);
    }
  }
}
