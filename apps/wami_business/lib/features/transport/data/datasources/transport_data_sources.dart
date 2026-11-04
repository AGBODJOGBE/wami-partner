import 'package:wami_core/wami_core.dart';

import '../../domain/entities/transport.dart';

abstract interface class TransportRemoteDataSource {
  Future<List<Departure>> departures(String establishmentId, DateTime day);
  Future<Departure> departure(String departureId);
  Future<Departure> sellSeat(String departureId, int seat, String passengerName);
  Future<Departure> setSeatBlocked(String departureId, int seat, bool blocked);
  Future<Seat> board(String departureId, String ticketCode);
  Future<Departure> reportDelay(String departureId, int minutes);
  Future<List<BusLine>> lines(String establishmentId);
  Future<BusLine> updateLinePrice(String lineId, int price);
}

BusLine _line(Map<String, dynamic> j) => BusLine(
      id: j['id'] as String,
      from: j['from'] as String,
      to: j['to'] as String,
      price: j['price'] as int,
      durationMinutes: j['duration_minutes'] as int,
      departuresPerDay: j['departures_per_day'] as int? ?? 1,
    );

Seat _seat(Map<String, dynamic> j) => Seat(
      number: j['number'] as int,
      state: SeatState.values.byName(j['state'] as String),
      passengerName: j['passenger_name'] as String?,
      ticketCode: j['ticket_code'] as String?,
    );

Departure _departure(Map<String, dynamic> j) => Departure(
      id: j['id'] as String,
      line: _line(j['line'] as Map<String, dynamic>),
      scheduledAt: DateTime.parse(j['scheduled_at'] as String),
      seats: [for (final s in (j['seats'] as List<dynamic>).cast<Map<String, dynamic>>()) _seat(s)],
      delayMinutes: j['delay_minutes'] as int? ?? 0,
      departed: j['departed'] as bool? ?? false,
    );

/// Endpoints à valider.
class TransportApiDataSource implements TransportRemoteDataSource {
  const TransportApiDataSource(this._api);
  final ApiClient _api;

  @override
  Future<List<Departure>> departures(String establishmentId, DateTime day) async {
    final j = await _api.get('/v1/business/establishments/$establishmentId/departures', query: {
      'date': '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
    });
    return [for (final d in (j['items'] as List<dynamic>).cast<Map<String, dynamic>>()) _departure(d)];
  }

  @override
  Future<Departure> departure(String departureId) async => _departure(await _api.get('/v1/business/departures/$departureId'));

  @override
  Future<Departure> sellSeat(String departureId, int seat, String passengerName) async => _departure(await _api.post(
        '/v1/business/departures/$departureId/seats/$seat/sell',
        body: {'passenger_name': passengerName, 'channel': 'counter'},
      ));

  @override
  Future<Departure> setSeatBlocked(String departureId, int seat, bool blocked) async =>
      _departure(await _api.put('/v1/business/departures/$departureId/seats/$seat', body: {'blocked': blocked}));

  @override
  Future<Seat> board(String departureId, String ticketCode) async =>
      _seat(await _api.post('/v1/business/departures/$departureId/board', body: {'ticket_code': ticketCode}));

  @override
  Future<Departure> reportDelay(String departureId, int minutes) async =>
      _departure(await _api.post('/v1/business/departures/$departureId/delay', body: {'minutes': minutes}));

  @override
  Future<List<BusLine>> lines(String establishmentId) async {
    final j = await _api.get('/v1/business/establishments/$establishmentId/lines');
    return [for (final l in (j['items'] as List<dynamic>).cast<Map<String, dynamic>>()) _line(l)];
  }

  @override
  Future<BusLine> updateLinePrice(String lineId, int price) async =>
      _line(await _api.put('/v1/business/lines/$lineId', body: {'price': price}));
}

/// Démo : 3 départs du jour, bus de 30 places. Billet de démo : 300512 (départ de 14 h).
class TransportFakeDataSource implements TransportRemoteDataSource {
  TransportFakeDataSource(this._fake) {
    final now = DateTime.now();
    DateTime at(int minutesFromNow) {
      final t = now.add(Duration(minutes: minutesFromNow));
      return DateTime(t.year, t.month, t.day, t.hour, (t.minute ~/ 15) * 15);
    }

    _departures.addAll([
      Departure(id: 'd1', line: _lines[0], scheduledAt: at(-30), seats: _seats(30, sold: 28, counterEvery: 3), departed: true),
      Departure(id: 'd2', line: _lines[1], scheduledAt: at(40), seats: _seats(30, sold: 24, counterEvery: 4, blocked: const [1])),
      Departure(id: 'd3', line: _lines[0], scheduledAt: at(240), seats: _seats(30, sold: 9, counterEvery: 5)),
    ]);
  }

  final FakeBackend _fake;
  final List<Departure> _departures = [];
  final List<BusLine> _lines = [
    const BusLine(id: 'cot-pkou', from: 'Cotonou', to: 'Parakou', price: 9000, durationMinutes: 420, departuresPerDay: 3),
    const BusLine(id: 'cot-nati', from: 'Cotonou', to: 'Natitingou', price: 12000, durationMinutes: 600, departuresPerDay: 1),
    const BusLine(id: 'cot-boh', from: 'Cotonou', to: 'Bohicon', price: 3000, durationMinutes: 150, departuresPerDay: 4),
  ];

  static const _names = ['Adjoa', 'Bio', 'Chabi', 'Dossou', 'Eyram', 'Fifamè', 'Gado', 'Hounkpè'];

  static List<Seat> _seats(int total, {required int sold, required int counterEvery, List<int> blocked = const []}) {
    var n = 0;
    return [
      for (var i = 1; i <= total; i++)
        if (blocked.contains(i))
          Seat(number: i, state: SeatState.blocked)
        else if (n < sold)
          Seat(
            number: i,
            state: (n++ % counterEvery == 0) ? SeatState.soldCounter : SeatState.soldApp,
            passengerName: '${_names[i % _names.length]} ${String.fromCharCode(65 + i % 26)}.',
            ticketCode: (300500 + i).toString(),
          )
        else
          Seat(number: i),
    ];
  }

  int _index(String id) {
    final i = _departures.indexWhere((d) => d.id == id);
    if (i < 0) throw const BusinessRuleException('unavailable');
    return i;
  }

  Departure _updateSeat(String departureId, int number, Seat Function(Seat s) change) {
    final i = _index(departureId);
    final d = _departures[i];
    return _departures[i] = d.copyWith(seats: [for (final s in d.seats) s.number == number ? change(s) : s]);
  }

  @override
  Future<List<Departure>> departures(String establishmentId, DateTime day) async {
    await _fake.latency(0.5);
    return List.of(_departures);
  }

  @override
  Future<Departure> departure(String departureId) async {
    await _fake.latency(0.3);
    return _departures[_index(departureId)];
  }

  @override
  Future<Departure> sellSeat(String departureId, int seat, String passengerName) async {
    await _fake.latency(0.5);
    final d = _departures[_index(departureId)];
    // Le serveur tranche si l'app a vendu la même place une seconde plus tôt.
    if (d.seats.firstWhere((s) => s.number == seat).state != SeatState.free) throw const BusinessRuleException('unavailable');
    return _updateSeat(departureId, seat, (s) => s.copyWith(
          state: SeatState.soldCounter,
          passengerName: passengerName,
          ticketCode: (400000 + DateTime.now().millisecondsSinceEpoch % 100000).toString(),
        ));
  }

  @override
  Future<Departure> setSeatBlocked(String departureId, int seat, bool blocked) async {
    await _fake.latency(0.3);
    return _updateSeat(departureId, seat, (s) => s.copyWith(state: blocked ? SeatState.blocked : SeatState.free));
  }

  @override
  Future<Seat> board(String departureId, String ticketCode) async {
    await _fake.latency(0.4);
    final d = _departures[_index(departureId)];
    final matches = d.seats.where((s) => s.ticketCode == ticketCode);
    if (matches.isEmpty) throw const BusinessRuleException('unknown_ticket', 'Billet inconnu pour ce départ. En démo : 300512.');
    final seat = matches.first;
    if (seat.state == SeatState.boarded) throw const BusinessRuleException('already_boarded', 'Ce voyageur est déjà à bord.');
    _updateSeat(departureId, seat.number, (s) => s.copyWith(state: SeatState.boarded));
    return seat.copyWith(state: SeatState.boarded);
  }

  @override
  Future<Departure> reportDelay(String departureId, int minutes) async {
    await _fake.latency(0.4);
    final i = _index(departureId);
    return _departures[i] = _departures[i].copyWith(delayMinutes: minutes);
  }

  @override
  Future<List<BusLine>> lines(String establishmentId) async {
    await _fake.latency(0.4);
    return List.of(_lines);
  }

  @override
  Future<BusLine> updateLinePrice(String lineId, int price) async {
    await _fake.latency(0.3);
    final i = _lines.indexWhere((l) => l.id == lineId);
    if (i < 0) throw const BusinessRuleException('unavailable');
    return _lines[i] = _lines[i].copyWith(price: price);
  }
}
