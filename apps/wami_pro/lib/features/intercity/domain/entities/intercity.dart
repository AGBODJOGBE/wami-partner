import 'package:equatable/equatable.dart';

class GeoPoint extends Equatable {
  const GeoPoint({required this.label, required this.city, required this.lat, required this.lng});
  final String label;
  final String city;
  final double lat;
  final double lng;

  @override
  List<Object?> get props => [label, city, lat, lng];
}

/// Trajet interurbain publié par le chauffeur (places à la réservation).
class IntercityOffer extends Equatable {
  const IntercityOffer({
    required this.id,
    required this.number,
    required this.origin,
    required this.destination,
    required this.departure,
    required this.seats,
    required this.pricePerSeat,
    required this.status,
  });

  final String id;
  final String number;
  final String origin;
  final String destination;
  final DateTime departure;
  final int seats;
  final int pricePerSeat;

  /// `PUBLISHED`, `FULL`, `IN_PROGRESS`, `COMPLETED`, `CANCELLED`, `EXPIRED`.
  final String status;

  String get statusLabel => switch (status) {
        'PUBLISHED' => 'Publié',
        'FULL' => 'Complet',
        'IN_PROGRESS' => 'En route',
        'COMPLETED' => 'Terminé',
        'CANCELLED' => 'Annulé',
        'EXPIRED' => 'Expiré',
        _ => status,
      };

  /// Le serveur n'autorise le départ qu'à l'état « publié » (au moins une réservation confirmée).
  bool get canStart => status == 'PUBLISHED';
  bool get canComplete => status == 'IN_PROGRESS';
  bool get canCancel => status == 'PUBLISHED';
  bool get isOpen => status == 'PUBLISHED' || status == 'FULL' || status == 'IN_PROGRESS';

  IntercityOffer withStatus(String s) => IntercityOffer(
        id: id, number: number, origin: origin, destination: destination,
        departure: departure, seats: seats, pricePerSeat: pricePerSeat, status: s,
      );

  @override
  List<Object?> get props => [id, number, origin, destination, departure, seats, pricePerSeat, status];
}

class OfferDraft extends Equatable {
  const OfferDraft({required this.origin, required this.destination, required this.departure, required this.seats, required this.pricePerSeat, this.description});
  final GeoPoint origin;
  final GeoPoint destination;
  final DateTime departure;
  final int seats;
  final int pricePerSeat;
  final String? description;

  @override
  List<Object?> get props => [origin, destination, departure, seats, pricePerSeat, description];
}

/// Trajet quotidien proposé à un passager précis.
class DailyRoute extends Equatable {
  const DailyRoute({
    required this.id,
    required this.passengerId,
    required this.days,
    required this.time,
    required this.pricePerRide,
    required this.status,
    required this.pickup,
    required this.dropoff,
  });

  final String id;
  final String passengerId;
  final List<String> days;
  final String time;
  final int pricePerRide;

  /// `ACTIVE`, `PAUSED`, `CANCELLED`, `EXPIRED`.
  final String status;
  final String pickup;
  final String dropoff;

  String get statusLabel => switch (status) {
        'ACTIVE' => 'Actif',
        'PAUSED' => 'En pause',
        'CANCELLED' => 'Annulé',
        'EXPIRED' => 'Expiré',
        _ => status,
      };

  DailyRoute withStatus(String s) => DailyRoute(
        id: id, passengerId: passengerId, days: days, time: time,
        pricePerRide: pricePerRide, status: s, pickup: pickup, dropoff: dropoff,
      );

  @override
  List<Object?> get props => [id, passengerId, days, time, pricePerRide, status, pickup, dropoff];
}

class RouteDraft extends Equatable {
  const RouteDraft({
    required this.passengerId,
    required this.pickup,
    required this.dropoff,
    required this.days,
    required this.time,
    required this.startDate,
    required this.pricePerRide,
    this.cash = true,
  });

  final String passengerId;
  final GeoPoint pickup;
  final GeoPoint dropoff;

  /// `MONDAY` … `SUNDAY`.
  final List<String> days;

  /// `HH:MM`.
  final String time;
  final DateTime startDate;
  final int pricePerRide;

  /// Espèces ou portefeuille (les deux seuls modes acceptés).
  final bool cash;

  @override
  List<Object?> get props => [passengerId, pickup, dropoff, days, time, startDate, pricePerRide, cash];
}
