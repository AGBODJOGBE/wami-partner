import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../error/exceptions.dart';
import 'auth_interceptor.dart';

/// Client HTTP partagé par toutes les sources de données distantes.
/// Il ne renvoie que du JSON décodé et ne lève que des exceptions de `core/error`.
class ApiClient {
  ApiClient(AppConfig config, AuthInterceptor authInterceptor)
      : _dio = Dio(
          BaseOptions(
            baseUrl: config.apiBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 20),
            headers: {'Accept': 'application/json', 'Accept-Language': 'fr'},
          ),
        )..interceptors.add(authInterceptor);

  final Dio _dio;

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) {
    return _send(() => _dio.get<Map<String, dynamic>>(path, queryParameters: query));
  }

  Future<Map<String, dynamic>> post(String path, {Object? body}) {
    return _send(() => _dio.post<Map<String, dynamic>>(path, data: body));
  }

  Future<Map<String, dynamic>> put(String path, {Object? body}) {
    return _send(() => _dio.put<Map<String, dynamic>>(path, data: body));
  }

  Future<Map<String, dynamic>> _send(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      final response = await request();
      return response.data ?? <String, dynamic>{};
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Exception _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const NetworkException();
      default:
        final data = e.response?.data;
        if (data is Map<String, dynamic> && data['code'] is String) {
          return BusinessRuleException(data['code'] as String, data['message'] as String?);
        }
        return ServerException(statusCode: e.response?.statusCode, message: e.message);
    }
  }
}
