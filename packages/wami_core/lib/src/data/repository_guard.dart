import '../error/exceptions.dart';
import '../error/failures.dart';
import '../utils/result.dart';

/// Exécute un appel de source de données et convertit les exceptions en [Failure].
/// Utilisé par toutes les implémentations de repository.
Future<Result<T>> guard<T>(Future<T> Function() call) async {
  try {
    return Ok(await call());
  } on NetworkException {
    return const Err(NetworkFailure());
  } on BusinessRuleException catch (e) {
    return Err(_mapBusinessRule(e));
  } on ServerException catch (e) {
    return Err(ServerFailure(e.message ?? const ServerFailure().message));
  } catch (_) {
    return const Err(UnexpectedFailure());
  }
}

Failure _mapBusinessRule(BusinessRuleException e) {
  return switch (e.code) {
    'insufficient_funds' => const InsufficientFundsFailure(),
    'unavailable' => const UnavailableFailure(),
    _ => ValidationFailure(e.message ?? 'Opération refusée.'),
  };
}
