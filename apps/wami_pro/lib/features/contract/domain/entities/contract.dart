import 'package:equatable/equatable.dart';

enum InstallmentState {
  pending('À venir'),
  collecting('En recouvrement'),
  paid('Payée'),
  late('Impayée'),
  cancelled('Annulée');

  const InstallmentState(this.label);
  final String label;
}

class Installment extends Equatable {
  const Installment({
    required this.number,
    required this.dueDate,
    required this.amount,
    required this.paid,
    required this.state,
  });
  final int number;
  final DateTime dueDate;
  final int amount;
  final int paid;
  final InstallmentState state;

  @override
  List<Object?> get props => [number, dueDate, amount, paid, state];
}

/// Contrat de location-vente du véhicule (échéances prélevées sur les revenus).
class VehicleContract extends Equatable {
  const VehicleContract({
    required this.status,
    required this.total,
    required this.paid,
    required this.remaining,
    required this.unpaidCount,
    required this.blocked,
    required this.byRevenue,
    required this.installments,
    this.nextDueDate,
    this.nextAmount,
  });

  /// `ACTIF`, `SUSPENDU`, `TERMINE` ou `ROMPU`.
  final String status;
  final int total;
  final int paid;
  final int remaining;
  final int unpaidCount;

  /// Un chauffeur bloqué pour impayés ne reçoit plus de missions et ne peut plus retirer.
  final bool blocked;

  /// Remboursement prélevé sur les revenus plutôt que par échéancier.
  final bool byRevenue;
  final List<Installment> installments;
  final DateTime? nextDueDate;
  final int? nextAmount;

  double get progress => total == 0 ? 0 : (paid / total).clamp(0, 1).toDouble();

  @override
  List<Object?> get props =>
      [status, total, paid, remaining, unpaidCount, blocked, byRevenue, installments, nextDueDate, nextAmount];
}
