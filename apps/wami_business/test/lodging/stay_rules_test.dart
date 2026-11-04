import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wami_core/wami_core.dart';
import 'package:wami_business/features/lodging/domain/entities/lodging.dart';
import 'package:wami_business/features/lodging/domain/repositories/lodging_repository.dart';
import 'package:wami_business/features/lodging/domain/usecases/lodging_usecases.dart';

class _Repo extends Mock implements LodgingRepository {}

final _d0 = DateTime(2026, 11, 10);
DateTime _d(int offset) => DateTime(_d0.year, _d0.month, _d0.day + offset);

const _suite = RoomType(id: 'suite', name: 'Suite', nightlyPrice: 65000, units: 1, openUnits: 1);

Booking _booking(String id, int from, int to, {BookingStatus status = BookingStatus.confirmed}) => Booking(
      id: id,
      code: '000000',
      guestName: 'X',
      roomTypeId: 'suite',
      checkIn: _d(from),
      checkOut: _d(to),
      amount: 0,
      status: status,
    );

void main() {
  group('StayRules', () {
    test('la nuit du départ est libre (le client part le matin)', () {
      final bookings = [_booking('a', 0, 2)];
      expect(StayRules.freeUnits(_suite, bookings, _d(0), _d(1)), 0);
      expect(StayRules.freeUnits(_suite, bookings, _d(2), _d(3)), 1);
    });

    test('une demande en attente bloque déjà la chambre, une refusée non', () {
      expect(StayRules.freeUnits(_suite, [_booking('a', 0, 1, status: BookingStatus.pending)], _d(0), _d(1)), 0);
      expect(StayRules.freeUnits(_suite, [_booking('a', 0, 1, status: BookingStatus.rejected)], _d(0), _d(1)), 1);
    });

    test('la nuit la plus chargée de la période décide', () {
      expect(StayRules.freeUnits(_suite, [_booking('a', 3, 4)], _d(0), _d(5)), 0);
    });
  });

  group('CreateDeskBooking', () {
    late _Repo repo;
    late CreateDeskBooking usecase;

    setUpAll(() => registerFallbackValue(
          DeskBookingRequest(establishmentId: '', roomTypeId: '', guestName: '', checkIn: _d0, checkOut: _d0),
        ));

    setUp(() {
      repo = _Repo();
      usecase = CreateDeskBooking(repo, clock: () => _d0);
    });

    DeskBookingRequest request(int from, int to) => DeskBookingRequest(
          establishmentId: 'h1',
          roomTypeId: 'suite',
          guestName: 'Client comptoir',
          checkIn: _d(from),
          checkOut: _d(to),
        );

    test('refuse le surbooking', () async {
      when(() => repo.getPlanning('h1', _d(1), 2)).thenAnswer(
        (_) async => Ok(Planning(start: _d(1), days: 2, roomTypes: const [_suite], bookings: [_booking('a', 2, 3)])),
      );
      final r = await usecase(request(1, 3));
      expect((r as Err<Booking>).failure, isA<UnavailableFailure>());
      verifyNever(() => repo.createDeskBooking(any()));
    });

    test('refuse une arrivée dans le passé', () async {
      final r = await usecase(request(-1, 1));
      expect((r as Err<Booking>).failure, isA<ValidationFailure>());
    });

    test('refuse zéro nuit', () async {
      final r = await usecase(request(1, 1));
      expect((r as Err<Booking>).failure, isA<ValidationFailure>());
    });
  });
}
