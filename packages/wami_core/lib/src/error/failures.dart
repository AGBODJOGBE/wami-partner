import 'package:equatable/equatable.dart';

/// Erreurs vues par les couches *domain* et *presentation*.
/// Chaque échec porte un message prêt à afficher, en français.
sealed class Failure extends Equatable {
  const Failure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Le service est momentanément indisponible.']);
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Pas de connexion internet. Vérifiez votre réseau.']);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class InsufficientFundsFailure extends Failure {
  const InsufficientFundsFailure([super.message = 'Solde insuffisant. Rechargez votre portefeuille.']);
}

final class UnavailableFailure extends Failure {
  const UnavailableFailure([super.message = 'Ce choix n’est plus disponible.']);
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Une erreur inattendue est survenue.']);
}
