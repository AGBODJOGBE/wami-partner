import 'package:equatable/equatable.dart';

enum HistoryOutcome {
  done('Terminée'),
  cancelled('Annulée'),
  inProgress('En cours'),
  failed('Échouée');

  const HistoryOutcome(this.label);
  final String label;
}

/// Course passée, vue du chauffeur.
class HistoryRide extends Equatable {
  const HistoryRide({
    required this.id,
    required this.number,
    required this.outcome,
    required this.statusLabel,
    required this.date,
    required this.pickup,
    required this.dropoff,
    required this.price,
    required this.earnings,
    required this.passenger,
    this.rating,
  });

  final String id;
  final String number;
  final HistoryOutcome outcome;
  final String statusLabel;
  final DateTime date;
  final String pickup;
  final String dropoff;
  final int price;

  /// Gain du chauffeur (`null` si la course n'a pas abouti).
  final int? earnings;
  final String passenger;

  /// Note donnée par le passager.
  final int? rating;

  @override
  List<Object?> get props => [id, number, outcome, statusLabel, date, pickup, dropoff, price, earnings, passenger, rating];
}

/// Livraison passée.
class HistoryDelivery extends Equatable {
  const HistoryDelivery({
    required this.id,
    required this.number,
    required this.outcome,
    required this.statusLabel,
    required this.date,
    required this.pickup,
    required this.dropoff,
    required this.price,
    this.cancelReason,
  });

  final String id;
  final String number;
  final HistoryOutcome outcome;
  final String statusLabel;
  final DateTime date;
  final String pickup;
  final String dropoff;
  final int price;
  final String? cancelReason;

  @override
  List<Object?> get props => [id, number, outcome, statusLabel, date, pickup, dropoff, price, cancelReason];
}
