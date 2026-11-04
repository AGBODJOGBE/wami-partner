import 'package:wami_core/wami_core.dart';

import '../../domain/entities/lodging.dart';
import '../../domain/repositories/lodging_repository.dart';

abstract interface class LodgingRemoteDataSource {
  Future<Planning> planning(String establishmentId, DateTime start, int days);
  Future<Booking> confirm(String bookingId);
  Future<Booking> reject(String bookingId, String reason);
  Future<Booking> createDeskBooking(DeskBookingRequest r);
  Future<Booking> checkIn(String establishmentId, String code);
  Future<List<RoomType>> roomTypes(String establishmentId);
  Future<RoomType> updateRoomType(String establishmentId, RoomType t);
}

String _day(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

RoomType _type(Map<String, dynamic> j) => RoomType(
      id: j['id'] as String,
      name: j['name'] as String,
      nightlyPrice: j['nightly_price'] as int,
      units: j['units'] as int,
      openUnits: j['open_units'] as int,
      capacity: j['capacity'] as int? ?? 2,
    );

Booking _booking(Map<String, dynamic> j) => Booking(
      id: j['id'] as String,
      code: j['code'] as String,
      guestName: j['guest_name'] as String,
      roomTypeId: j['room_type_id'] as String,
      checkIn: DateTime.parse(j['check_in'] as String),
      checkOut: DateTime.parse(j['check_out'] as String),
      amount: j['amount'] as int,
      status: BookingStatus.values.byName(j['status'] as String),
      channel: BookingChannel.values.byName(j['channel'] as String? ?? 'app'),
    );

/// Endpoints à valider.
class LodgingApiDataSource implements LodgingRemoteDataSource {
  const LodgingApiDataSource(this._api);
  final ApiClient _api;

  @override
  Future<Planning> planning(String establishmentId, DateTime start, int days) async {
    final j = await _api.get('/v1/business/establishments/$establishmentId/planning', query: {'from': _day(start), 'days': days});
    return Planning(
      start: start,
      days: days,
      roomTypes: [for (final t in (j['room_types'] as List<dynamic>).cast<Map<String, dynamic>>()) _type(t)],
      bookings: [for (final b in (j['bookings'] as List<dynamic>).cast<Map<String, dynamic>>()) _booking(b)],
    );
  }

  @override
  Future<Booking> confirm(String bookingId) async => _booking(await _api.post('/v1/business/bookings/$bookingId/confirm'));

  @override
  Future<Booking> reject(String bookingId, String reason) async =>
      _booking(await _api.post('/v1/business/bookings/$bookingId/reject', body: {'reason': reason}));

  @override
  Future<Booking> createDeskBooking(DeskBookingRequest r) async => _booking(await _api.post(
        '/v1/business/establishments/${r.establishmentId}/bookings',
        body: {
          'room_type_id': r.roomTypeId,
          'guest_name': r.guestName,
          'check_in': _day(r.checkIn),
          'check_out': _day(r.checkOut),
          'channel': 'desk',
        },
      ));

  @override
  Future<Booking> checkIn(String establishmentId, String code) async =>
      _booking(await _api.post('/v1/business/establishments/$establishmentId/check-in', body: {'code': code}));

  @override
  Future<List<RoomType>> roomTypes(String establishmentId) async {
    final j = await _api.get('/v1/business/establishments/$establishmentId/room-types');
    return [for (final t in (j['items'] as List<dynamic>).cast<Map<String, dynamic>>()) _type(t)];
  }

  @override
  Future<RoomType> updateRoomType(String establishmentId, RoomType t) async => _type(await _api.put(
        '/v1/business/establishments/$establishmentId/room-types/${t.id}',
        body: {'nightly_price': t.nightlyPrice, 'open_units': t.openUnits},
      ));
}

/// Démo : 3 types de chambres, quelques réservations ; code d'arrivée 482193.
class LodgingFakeDataSource implements LodgingRemoteDataSource {
  LodgingFakeDataSource(this._fake) {
    final today = dateOnly(DateTime.now());
    DateTime d(int offset) => DateTime(today.year, today.month, today.day + offset);
    _bookings.addAll([
      Booking(id: 'b1', code: '482193', guestName: 'Mawuli A.', roomTypeId: 'std', checkIn: d(0), checkOut: d(2), amount: 50000, status: BookingStatus.confirmed),
      Booking(id: 'b2', code: '730015', guestName: 'Carine D.', roomTypeId: 'sup', checkIn: d(0), checkOut: d(1), amount: 38000, status: BookingStatus.confirmed),
      Booking(id: 'b3', code: '115620', guestName: 'Ismaël S.', roomTypeId: 'std', checkIn: d(1), checkOut: d(4), amount: 75000),
      Booking(id: 'b4', code: '904471', guestName: 'Edwige K.', roomTypeId: 'suite', checkIn: d(2), checkOut: d(3), amount: 65000),
      Booking(id: 'b5', code: '268804', guestName: 'Famille Houngbo', roomTypeId: 'std', checkIn: d(-1), checkOut: d(3), amount: 100000, status: BookingStatus.checkedIn),
      Booking(id: 'b6', code: '551902', guestName: 'Yannick T.', roomTypeId: 'sup', checkIn: d(3), checkOut: d(6), amount: 114000, status: BookingStatus.confirmed),
    ]);
  }

  final FakeBackend _fake;
  final List<Booking> _bookings = [];
  final List<RoomType> _types = [
    const RoomType(id: 'std', name: 'Standard ventilée', nightlyPrice: 25000, units: 6, openUnits: 4),
    const RoomType(id: 'sup', name: 'Supérieure climatisée', nightlyPrice: 38000, units: 4, openUnits: 3),
    const RoomType(id: 'suite', name: 'Suite vue lagune', nightlyPrice: 65000, units: 1, openUnits: 1, capacity: 4),
  ];
  var _seq = 7;

  int _index(String id) {
    final i = _bookings.indexWhere((b) => b.id == id);
    if (i < 0) throw const BusinessRuleException('unavailable');
    return i;
  }

  @override
  Future<Planning> planning(String establishmentId, DateTime start, int days) async {
    await _fake.latency(0.5);
    return Planning(start: start, days: days, roomTypes: List.of(_types), bookings: List.of(_bookings));
  }

  @override
  Future<Booking> confirm(String bookingId) async {
    await _fake.latency(0.4);
    final i = _index(bookingId);
    return _bookings[i] = _bookings[i].copyWith(status: BookingStatus.confirmed);
  }

  @override
  Future<Booking> reject(String bookingId, String reason) async {
    await _fake.latency(0.4);
    final i = _index(bookingId);
    return _bookings[i] = _bookings[i].copyWith(status: BookingStatus.rejected);
  }

  @override
  Future<Booking> createDeskBooking(DeskBookingRequest r) async {
    await _fake.latency(0.6);
    final type = _types.firstWhere((t) => t.id == r.roomTypeId, orElse: () => throw const BusinessRuleException('unavailable'));
    // Le serveur revérifie : deux réceptionnistes peuvent réserver la dernière chambre en même temps.
    if (StayRules.freeUnits(type, _bookings, r.checkIn, r.checkOut) <= 0) throw const BusinessRuleException('unavailable');
    final nights = dateOnly(r.checkOut).difference(dateOnly(r.checkIn)).inDays;
    final b = Booking(
      id: 'b${_seq++}',
      code: (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString(),
      guestName: r.guestName,
      roomTypeId: r.roomTypeId,
      checkIn: dateOnly(r.checkIn),
      checkOut: dateOnly(r.checkOut),
      amount: nights * type.nightlyPrice,
      status: BookingStatus.confirmed,
      channel: BookingChannel.desk,
    );
    _bookings.add(b);
    return b;
  }

  @override
  Future<Booking> checkIn(String establishmentId, String code) async {
    await _fake.latency(0.5);
    final i = _bookings.indexWhere((b) => b.code == code);
    if (i < 0) throw const BusinessRuleException('unknown_code', 'Code inconnu. En démo : 482193.');
    final b = _bookings[i];
    if (b.status == BookingStatus.checkedIn) throw const BusinessRuleException('already', 'Ce client est déjà arrivé.');
    if (b.status != BookingStatus.confirmed) throw const BusinessRuleException('not_confirmed', 'Réservation non confirmée.');
    return _bookings[i] = b.copyWith(status: BookingStatus.checkedIn);
  }

  @override
  Future<List<RoomType>> roomTypes(String establishmentId) async {
    await _fake.latency(0.4);
    return List.of(_types);
  }

  @override
  Future<RoomType> updateRoomType(String establishmentId, RoomType t) async {
    await _fake.latency(0.4);
    final i = _types.indexWhere((x) => x.id == t.id);
    if (i < 0) throw const BusinessRuleException('unavailable');
    return _types[i] = t;
  }
}
