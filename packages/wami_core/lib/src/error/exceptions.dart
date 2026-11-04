/// Exceptions levées par la couche *data* (sources de données).
/// Elles ne sortent jamais d'un repository : celui-ci les convertit en [Failure].
class ServerException implements Exception {
  const ServerException({this.statusCode, this.message});
  final int? statusCode;
  final String? message;

  @override
  String toString() => 'ServerException($statusCode, $message)';
}

class NetworkException implements Exception {
  const NetworkException();
}

class CacheException implements Exception {
  const CacheException();
}

/// Règle métier refusée par le serveur (ex. solde insuffisant).
class BusinessRuleException implements Exception {
  const BusinessRuleException(this.code, [this.message]);
  final String code;
  final String? message;
}
