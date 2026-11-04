import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wami_core/wami_core.dart';
import 'package:wami_business/features/transport/domain/entities/transport.dart';
import 'package:wami_business/features/transport/domain/repositories/transport_repository.dart';
import 'package:wami_business/features/transport/domain/usecases/transport_usecases.dart';

class _Repo extends Mock implements TransportRepository {}

const _line = BusLine(id: 'l', from: 'Cotonou', to: 'Parakou', price: 9000, durationMinutes: 420, departuresPerDay: 1);
final _at = DateTime(2026, 11, 4, 14);

final _departure = Departure(
  id: 'd1',
  line: _line,
  scheduledAt: _at,
  seats: const [
    Seat(number: 1, state: SeatState.soldApp, ticketCode: '300501'),
    Seat(number: 2),
    Seat(number: 3, state: SeatState.blocked),
  ],
);

void main() {
  late _Repo repo;
  setUp(() => repo = _Repo());

  test('compteurs du départ', () {
    expect(_departure.sold, 1);
    expect(_departure.free, 1);
  });

  test('une place vendue en ligne ne peut pas être revendue au guichet', () async {
    final r = await SellSeat(repo)(SellSeatParams(_departure, 1, 'Client'));
    expect((r as Err<Departure>).failure, isA<UnavailableFailure>());
    verifyNever(() => repo.sellSeat('d1', 1, 'Client'));
  });

  test('une place vendue ne peut pas être bloquée', () async {
    final r = await ToggleSeatBlocked(repo)(BlockSeatParams(_departure, 1));
    expect(r.isOk, isFalse);
  });

  test('embarquement fermé plus de 45 min avant le départ', () async {
    final r = await BoardPassenger(repo)(BoardParams(_departure, '300501', now: _at.subtract(const Duration(hours: 2))));
    expect(r.isOk, isFalse);
  });

  test('retard hors bornes refusé', () async {
    final r = await ReportDelay(repo)(DelayParams(_departure, 2));
    expect((r as Err<Departure>).failure, isA<ValidationFailure>());
  });
}
