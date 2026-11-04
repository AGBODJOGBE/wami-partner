import '../utils/result.dart';

/// Contrat d'un cas d'usage : une seule action métier, une seule méthode.
abstract interface class UseCase<T, P> {
  Future<Result<T>> call(P params);
}

/// Cas d'usage qui suit un état dans le temps (course, colis…).
abstract interface class StreamUseCase<T, P> {
  Stream<T> call(P params);
}

/// Paramètre vide.
final class NoParams {
  const NoParams();
}
