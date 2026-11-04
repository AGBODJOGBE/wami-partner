import 'package:equatable/equatable.dart';

/// Date sans heure : les nuitées se comptent en jours calendaires.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class RoomType extends Equatable {
  const RoomType({
    required this.id,
    required this.name,
    required this.nightlyPrice,
    required this.units,
    required this.openUnits,
    this.capacity = 2,
  });

  final String id;
  final String name;
  final int nightlyPrice;

  /// Chambres de ce type dans l'établissement.
  final int units;

  /// Chambres ouvertes à la réservation WAMI (le reste est vendu ailleurs ou en travaux).
  final int openUnits;
  final int capacity;

  RoomType copyWith({int? nightlyPrice, int? openUnits}) => RoomType(
        id: id,
        name: name,
        nightlyPrice: nightlyPrice ?? this.nightlyPrice,
        units: units,
        openUnits: openUnits ?? this.openUnits,
        capacity: capacity,
      );

  @override
  List<Object?> get props => [id, name, nightlyPrice, units, openUnits, capacity];
}

enum BookingStatus {
  pending('À confirmer'),
  confirmed('Confirmée'),
  checkedIn('Arrivé'),
  checkedOut('Parti'),
  rejected('Refusée'),
  cancelled('Annulée');

  const BookingStatus(this.label);
  final String label;

  /// Une demande en attente bloque déjà la chambre, sinon on pourrait la promettre deux fois.
  bool get holdsRoom => this == pending || this == confirmed || this == checkedIn;
}

enum BookingChannel { app, desk }

class Booking extends Equatable {
  const Booking({
    required this.id,
    required this.code,
    required this.guestName,
    required this.roomTypeId,
    required this.checkIn,
    required this.checkOut,
    required this.amount,
    this.status = BookingStatus.pending,
    this.channel = BookingChannel.app,
  });

  final String id;

  /// Code à 6 chiffres présenté par le client à l'arrivée.
  final String code;
  final String guestName;
  final String roomTypeId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int amount;
  final BookingStatus status;
  final BookingChannel channel;

  int get nights => dateOnly(checkOut).difference(dateOnly(checkIn)).inDays;

  /// Occupe la nuit qui commence le jour [day].
  bool occupiesNight(DateTime day) {
    final d = dateOnly(day);
    return status.holdsRoom && !d.isBefore(dateOnly(checkIn)) && d.isBefore(dateOnly(checkOut));
  }

  Booking copyWith({BookingStatus? status}) => Booking(
        id: id,
        code: code,
        guestName: guestName,
        roomTypeId: roomTypeId,
        checkIn: checkIn,
        checkOut: checkOut,
        amount: amount,
        status: status ?? this.status,
        channel: channel,
      );

  @override
  List<Object?> get props => [id, code, guestName, roomTypeId, checkIn, checkOut, amount, status, channel];
}

/// Règles d'occupation : jamais plus de réservations qu'il n'y a de chambres ouvertes.
abstract final class StayRules {
  static int occupied(String roomTypeId, List<Booking> bookings, DateTime night) =>
      bookings.where((b) => b.roomTypeId == roomTypeId && b.occupiesNight(night)).length;

  /// Chambres libres sur toute la période [from, to[ (la nuit la plus chargée décide).
  static int freeUnits(RoomType type, List<Booking> bookings, DateTime from, DateTime to) {
    var free = type.openUnits;
    for (var d = dateOnly(from); d.isBefore(dateOnly(to)); d = DateTime(d.year, d.month, d.day + 1)) {
      final left = type.openUnits - occupied(type.id, bookings, d);
      if (left < free) free = left;
    }
    return free < 0 ? 0 : free;
  }
}

/// Planning d'une semaine pour un établissement.
class Planning extends Equatable {
  const Planning({required this.start, required this.days, required this.roomTypes, required this.bookings});
  final DateTime start;
  final int days;
  final List<RoomType> roomTypes;
  final List<Booking> bookings;

  List<DateTime> get dates => [for (var i = 0; i < days; i++) DateTime(start.year, start.month, start.day + i)];

  int free(RoomType t, DateTime day) => StayRules.freeUnits(t, bookings, day, DateTime(day.year, day.month, day.day + 1));

  List<Booking> get pending => bookings.where((b) => b.status == BookingStatus.pending).toList();

  List<Booking> arrivals(DateTime day) => bookings
      .where((b) => b.status == BookingStatus.confirmed && dateOnly(b.checkIn) == dateOnly(day))
      .toList();

  RoomType? typeOf(Booking b) {
    for (final t in roomTypes) {
      if (t.id == b.roomTypeId) return t;
    }
    return null;
  }

  @override
  List<Object?> get props => [start, days, roomTypes, bookings];
}
