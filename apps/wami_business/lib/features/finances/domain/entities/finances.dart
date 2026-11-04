import 'package:equatable/equatable.dart';

enum PayoutStatus {
  scheduled('Programmé'),
  paid('Versé'),
  failed('Échec');

  const PayoutStatus(this.label);
  final String label;
}

class PayoutLine extends Equatable {
  const PayoutLine(this.label, this.amount);
  final String label;

  /// Négatif pour une retenue.
  final int amount;

  @override
  List<Object?> get props => [label, amount];
}

/// Versement de WAMI vers l'établissement pour une période.
class Payout extends Equatable {
  const Payout({
    required this.id,
    required this.period,
    required this.date,
    required this.gross,
    required this.commission,
    required this.status,
    required this.method,
    this.adjustments = const [],
  });

  final String id;
  final String period;
  final DateTime date;

  /// Ventes encaissées par WAMI pour l'établissement.
  final int gross;
  final int commission;
  final PayoutStatus status;
  final String method;

  /// Remboursements, pénalités de retard, gestes commerciaux…
  final List<PayoutLine> adjustments;

  int get net => gross - commission + adjustments.fold(0, (s, a) => s + a.amount);

  @override
  List<Object?> get props => [id, period, date, gross, commission, status, method, adjustments];
}

class FinanceOverview extends Equatable {
  const FinanceOverview({
    required this.pending,
    required this.nextPayoutDate,
    required this.payoutMethod,
    required this.commissionRate,
    required this.months,
    required this.monthLabels,
    required this.payouts,
  });

  /// Montant qui sera versé au prochain versement.
  final int pending;
  final DateTime nextPayoutDate;
  final String payoutMethod;
  final double commissionRate;
  final List<int> months;
  final List<String> monthLabels;
  final List<Payout> payouts;

  @override
  List<Object?> get props => [pending, nextPayoutDate, payoutMethod, commissionRate, months, monthLabels, payouts];
}
