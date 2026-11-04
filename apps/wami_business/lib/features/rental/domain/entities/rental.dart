import 'package:equatable/equatable.dart';

/// Un bien proposé à la location longue durée.
class Listing extends Equatable {
  const Listing({
    required this.id,
    required this.title,
    required this.district,
    required this.monthlyRent,
    required this.rooms,
    this.rented = false,
  });

  final String id;
  final String title;
  final String district;
  final int monthlyRent;
  final int rooms;

  /// Loué : retiré des recherches, les demandes de visite sont refusées.
  final bool rented;

  Listing copyWith({bool? rented}) =>
      Listing(id: id, title: title, district: district, monthlyRent: monthlyRent, rooms: rooms, rented: rented ?? this.rented);

  @override
  List<Object?> get props => [id, title, district, monthlyRent, rooms, rented];
}

enum VisitStatus {
  pending('À traiter'),
  accepted('Confirmée'),
  proposed('Autre créneau proposé'),
  declined('Refusée');

  const VisitStatus(this.label);
  final String label;
}

class VisitRequest extends Equatable {
  const VisitRequest({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.visitorName,
    required this.requestedAt,
    this.status = VisitStatus.pending,
    this.proposedAt,
  });

  final String id;
  final String listingId;
  final String listingTitle;
  final String visitorName;
  final DateTime requestedAt;
  final VisitStatus status;
  final DateTime? proposedAt;

  /// Créneau retenu (celui proposé par le propriétaire s'il y en a un).
  DateTime get slot => proposedAt ?? requestedAt;

  VisitRequest copyWith({VisitStatus? status, DateTime? proposedAt}) => VisitRequest(
        id: id,
        listingId: listingId,
        listingTitle: listingTitle,
        visitorName: visitorName,
        requestedAt: requestedAt,
        status: status ?? this.status,
        proposedAt: proposedAt ?? this.proposedAt,
      );

  @override
  List<Object?> get props => [id, listingId, listingTitle, visitorName, requestedAt, status, proposedAt];
}

/// Plage où le propriétaire accepte de faire visiter (ex. samedi 9 h – 12 h).
class AvailabilityWindow extends Equatable {
  const AvailabilityWindow({required this.weekday, required this.startHour, required this.endHour});

  /// 1 = lundi … 7 = dimanche (comme DateTime.weekday).
  final int weekday;
  final int startHour;
  final int endHour;

  static const dayNames = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];

  bool get isValid => weekday >= 1 && weekday <= 7 && startHour >= 6 && endHour <= 21 && startHour < endHour;

  bool contains(DateTime t) => t.weekday == weekday && t.hour >= startHour && t.hour < endHour;

  String get label => '${dayNames[weekday - 1]} ${startHour}h – ${endHour}h';

  @override
  List<Object?> get props => [weekday, startHour, endHour];
}

/// Créneaux de visite d'une heure, calculés à partir des disponibilités.
abstract final class VisitSlots {
  static bool fits(DateTime slot, List<AvailabilityWindow> windows) => windows.any((w) => w.contains(slot));

  /// Les [count] prochains créneaux d'une heure après [now] (au moins 2 h de préavis).
  static List<DateTime> next(List<AvailabilityWindow> windows, DateTime now, {int count = 6}) {
    final out = <DateTime>[];
    if (windows.isEmpty) return out;
    final earliest = now.add(const Duration(hours: 2));
    for (var day = 0; day < 21 && out.length < count; day++) {
      final d = DateTime(now.year, now.month, now.day + day);
      final todays = windows.where((w) => w.weekday == d.weekday).toList()..sort((a, b) => a.startHour.compareTo(b.startHour));
      for (final w in todays) {
        for (var h = w.startHour; h < w.endHour && out.length < count; h++) {
          final slot = DateTime(d.year, d.month, d.day, h);
          if (slot.isAfter(earliest)) out.add(slot);
        }
      }
    }
    return out;
  }
}
