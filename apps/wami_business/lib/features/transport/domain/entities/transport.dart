import 'package:equatable/equatable.dart';

class BusLine extends Equatable {
  const BusLine({
    required this.id,
    required this.from,
    required this.to,
    required this.price,
    required this.durationMinutes,
    required this.departuresPerDay,
  });

  final String id;
  final String from;
  final String to;
  final int price;
  final int durationMinutes;
  final int departuresPerDay;

  String get label => '$from → $to';

  BusLine copyWith({int? price}) => BusLine(
        id: id,
        from: from,
        to: to,
        price: price ?? this.price,
        durationMinutes: durationMinutes,
        departuresPerDay: departuresPerDay,
      );

  @override
  List<Object?> get props => [id, from, to, price, durationMinutes, departuresPerDay];
}

enum SeatState {
  free('Libre'),
  soldApp('Vendu app'),
  soldCounter('Vendu guichet'),
  blocked('Bloqué'),
  boarded('À bord');

  const SeatState(this.label);
  final String label;

  bool get isSold => this == soldApp || this == soldCounter || this == boarded;
}

class Seat extends Equatable {
  const Seat({required this.number, this.state = SeatState.free, this.passengerName, this.ticketCode});
  final int number;
  final SeatState state;
  final String? passengerName;

  /// Code à 6 chiffres du billet, contrôlé à l'embarquement.
  final String? ticketCode;

  Seat copyWith({SeatState? state, String? passengerName, String? ticketCode}) => Seat(
        number: number,
        state: state ?? this.state,
        passengerName: passengerName ?? this.passengerName,
        ticketCode: ticketCode ?? this.ticketCode,
      );

  @override
  List<Object?> get props => [number, state, passengerName, ticketCode];
}

/// Un départ daté, avec un seul plan de places partagé entre l'app et le guichet
/// (c'est ce qui évite de vendre deux fois le même siège).
class Departure extends Equatable {
  const Departure({
    required this.id,
    required this.line,
    required this.scheduledAt,
    required this.seats,
    this.delayMinutes = 0,
    this.departed = false,
  });

  final String id;
  final BusLine line;
  final DateTime scheduledAt;
  final List<Seat> seats;
  final int delayMinutes;
  final bool departed;

  DateTime get effectiveAt => scheduledAt.add(Duration(minutes: delayMinutes));

  int count(SeatState s) => seats.where((x) => x.state == s).length;
  int get soldApp => count(SeatState.soldApp);
  int get soldCounter => count(SeatState.soldCounter);
  int get boarded => count(SeatState.boarded);
  int get sold => seats.where((x) => x.state.isSold).length;
  int get free => count(SeatState.free);
  double get fill => seats.isEmpty ? 0 : sold / seats.length;

  /// L'embarquement ouvre 45 min avant le départ (à valider).
  bool boardingOpen(DateTime now) => !departed && now.isAfter(effectiveAt.subtract(const Duration(minutes: 45)));

  Departure copyWith({List<Seat>? seats, int? delayMinutes, bool? departed}) => Departure(
        id: id,
        line: line,
        scheduledAt: scheduledAt,
        seats: seats ?? this.seats,
        delayMinutes: delayMinutes ?? this.delayMinutes,
        departed: departed ?? this.departed,
      );

  @override
  List<Object?> get props => [id, line, scheduledAt, seats, delayMinutes, departed];
}

abstract final class DelayRules {
  static const minMinutes = 5;
  static const maxMinutes = 240;
  static const presets = [15, 30, 45, 60, 90];
}
