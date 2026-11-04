import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wami_core/wami_core.dart';
import 'package:wami_business/features/rental/domain/entities/rental.dart';
import 'package:wami_business/features/rental/domain/repositories/rental_repository.dart';
import 'package:wami_business/features/rental/domain/usecases/rental_usecases.dart';

class _Repo extends Mock implements RentalRepository {}

// Mercredi 4 novembre 2026, 10 h.
final _now = DateTime(2026, 11, 4, 10);
const _saturdayMorning = AvailabilityWindow(weekday: DateTime.saturday, startHour: 9, endHour: 12);

final _visit = VisitRequest(
  id: 'v1',
  listingId: 'l1',
  listingTitle: 'Studio',
  visitorName: 'X',
  requestedAt: DateTime(2026, 11, 5, 18),
);

void main() {
  test('créneaux proposés : dans les plages, au moins 2 h à l’avance', () {
    final slots = VisitSlots.next(const [_saturdayMorning], _now, count: 4);
    expect(slots.first, DateTime(2026, 11, 7, 9));
    expect(slots.length, 4);
    expect(slots.every((s) => VisitSlots.fits(s, const [_saturdayMorning])), isTrue);
  });

  test('proposer hors disponibilités est refusé', () async {
    final repo = _Repo();
    final r = await ProposeVisitSlot(repo)(ProposeVisitParams(
      visit: _visit,
      slot: DateTime(2026, 11, 7, 15),
      windows: const [_saturdayMorning],
      now: _now,
    ));
    expect((r as Err<VisitRequest>).failure, isA<ValidationFailure>());
  });

  test('deux plages qui se chevauchent sont refusées', () async {
    final repo = _Repo();
    final r = await SaveAvailability(repo)(const SaveAvailabilityParams('e1', [
      _saturdayMorning,
      AvailabilityWindow(weekday: DateTime.saturday, startHour: 11, endHour: 13),
    ]));
    expect(r.isOk, isFalse);
  });
}
