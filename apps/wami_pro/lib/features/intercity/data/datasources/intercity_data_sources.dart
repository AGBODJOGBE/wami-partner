import 'dart:convert';

import 'package:wami_core/wami_core.dart';

import '../../../../shared/local_store.dart';
import '../../domain/entities/intercity.dart';

abstract interface class IntercityRemoteDataSource {
  Future<List<IntercityOffer>> offers();
  Future<List<DailyRoute>> routes();
  Future<IntercityOffer> publish(OfferDraft draft);
  Future<IntercityOffer> start(String offerId);
  Future<IntercityOffer> complete(String offerId);
  Future<IntercityOffer> cancel(String offerId, String reason);
  Future<DailyRoute> createRoute(RouteDraft draft);
  Future<DailyRoute> pauseRoute(String routeId, DateTime? resumeDate);
  Future<DailyRoute> resumeRoute(String routeId);
  Future<DailyRoute> cancelRoute(String routeId, String reason);
}

Map<String, dynamic> _offerJson(IntercityOffer o) => {
      'id': o.id, 'number': o.number, 'origin': o.origin, 'destination': o.destination,
      'departure': o.departure.toIso8601String(), 'seats': o.seats, 'price': o.pricePerSeat, 'status': o.status,
    };

IntercityOffer _offer(Map<String, dynamic> j) => IntercityOffer(
      id: '${j['id']}', number: '${j['number'] ?? ''}', origin: '${j['origin']}', destination: '${j['destination']}',
      departure: DateTime.tryParse('${j['departure']}')?.toLocal() ?? DateTime.now(),
      seats: (j['seats'] as num?)?.toInt() ?? 0, pricePerSeat: (j['price'] as num?)?.toInt() ?? 0, status: '${j['status']}',
    );

Map<String, dynamic> _routeJson(DailyRoute r) => {
      'id': r.id, 'passengerId': r.passengerId, 'days': r.days, 'time': r.time, 'price': r.pricePerRide,
      'status': r.status, 'pickup': r.pickup, 'dropoff': r.dropoff,
    };

DailyRoute _route(Map<String, dynamic> j) => DailyRoute(
      id: '${j['id']}', passengerId: '${j['passengerId']}', days: ((j['days'] as List<dynamic>?) ?? const []).cast<String>(),
      time: '${j['time']}', pricePerRide: (j['price'] as num?)?.toInt() ?? 0, status: '${j['status']}',
      pickup: '${j['pickup']}', dropoff: '${j['dropoff']}',
    );

/// `/api/driver/offers*` et `/api/driver/daily-routes*`.
///
/// Les identifiants sont gardés sur l'appareil faute de route de liste. Garde-fous du serveur :
/// un seul trajet actif à la fois ; départ possible seulement avec au moins un passager confirmé ;
/// annulation possible tant que le trajet est « publié ».
class IntercityApiDataSource implements IntercityRemoteDataSource {
  IntercityApiDataSource(this._api, this._store);
  final ApiClient _api;
  final LocalStore _store;

  static const _offersKey = 'intercity_offers';
  static const _routesKey = 'intercity_routes';

  Future<List<Map<String, dynamic>>> _read(String key) async {
    final raw = await _store.read(key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _write(String key, List<Map<String, dynamic>> items) => _store.write(key, jsonEncode(items));

  @override
  Future<List<IntercityOffer>> offers() async => (await _read(_offersKey)).map(_offer).toList().reversed.toList();

  @override
  Future<List<DailyRoute>> routes() async => (await _read(_routesKey)).map(_route).toList().reversed.toList();

  /// Véhicule actif et type de course correspondant (`PREMIUM` s'appelle `CONFORT` côté courses).
  Future<(String, String)> _vehicle() async {
    final v = await _api.get('/api/drivers/vehicle');
    final id = v['id'] as String?;
    if (id == null) throw const BusinessRuleException('no_vehicle', 'Aucun véhicule actif sur votre compte.');
    final type = switch (v['type']) {
      'MOTO' => 'MOTO',
      'TRICYCLE' => 'TRICYCLE',
      _ => switch (v['category']) { 'ECO' => 'ECO', 'PREMIUM' => 'CONFORT', 'VIP' => 'VIP', _ => 'STANDARD' },
    };
    return (id, type);
  }

  Future<IntercityOffer> _update(String id, String Function(IntercityOffer) status) async {
    final all = await _read(_offersKey);
    final i = all.indexWhere((o) => o['id'] == id);
    if (i < 0) throw const BusinessRuleException('unknown', 'Trajet introuvable sur cet appareil.');
    final updated = _offer(all[i]).withStatus(status(_offer(all[i])));
    all[i] = _offerJson(updated);
    await _write(_offersKey, all);
    return updated;
  }

  @override
  Future<IntercityOffer> publish(OfferDraft d) async {
    final (vehicleId, vehicleType) = await _vehicle();
    final j = await _api.post('/api/driver/offers', body: {
      'vehicleId': vehicleId,
      'vehicleType': vehicleType,
      'originLat': d.origin.lat,
      'originLng': d.origin.lng,
      'originAddress': d.origin.label,
      'originCity': d.origin.city,
      'destinationLat': d.destination.lat,
      'destinationLng': d.destination.lng,
      'destinationAddress': d.destination.label,
      'destinationCity': d.destination.city,
      'departureTime': d.departure.toUtc().toIso8601String(),
      'totalSeats': d.seats,
      'pricePerSeat': d.pricePerSeat,
      if (d.description != null && d.description!.trim().isNotEmpty) 'description': d.description!.trim(),
    });
    final offer = IntercityOffer(
      id: '${j['offerId']}',
      number: '${j['offerNumber'] ?? ''}',
      origin: d.origin.city,
      destination: d.destination.city,
      departure: d.departure,
      seats: d.seats,
      pricePerSeat: d.pricePerSeat,
      status: '${j['status'] ?? 'PUBLISHED'}',
    );
    final all = await _read(_offersKey)..add(_offerJson(offer));
    await _write(_offersKey, all);
    return offer;
  }

  @override
  Future<IntercityOffer> start(String id) async {
    final j = await _api.patch('/api/driver/offers/$id/start');
    return _update(id, (_) => '${j['status'] ?? 'IN_PROGRESS'}');
  }

  @override
  Future<IntercityOffer> complete(String id) async {
    final j = await _api.patch('/api/driver/offers/$id/complete');
    return _update(id, (_) => '${j['status'] ?? 'COMPLETED'}');
  }

  @override
  Future<IntercityOffer> cancel(String id, String reason) async {
    final j = await _api.delete('/api/driver/offers/$id', body: {'reason': reason});
    return _update(id, (_) => '${j['status'] ?? 'CANCELLED'}');
  }

  Future<DailyRoute> _updateRoute(String id, String status) async {
    final all = await _read(_routesKey);
    final i = all.indexWhere((r) => r['id'] == id);
    if (i < 0) throw const BusinessRuleException('unknown', 'Trajet introuvable sur cet appareil.');
    final updated = _route(all[i]).withStatus(status);
    all[i] = _routeJson(updated);
    await _write(_routesKey, all);
    return updated;
  }

  @override
  Future<DailyRoute> createRoute(RouteDraft d) async {
    final (vehicleId, vehicleType) = await _vehicle();
    final j = await _api.post('/api/driver/daily-routes', body: {
      'passengerId': d.passengerId.trim(),
      'vehicleId': vehicleId,
      'vehicleType': vehicleType,
      'scheduledDays': d.days,
      'departureTime': d.time,
      'startDate': d.startDate.toUtc().toIso8601String(),
      'pickupLat': d.pickup.lat,
      'pickupLng': d.pickup.lng,
      'pickupAddress': d.pickup.label,
      'dropoffLat': d.dropoff.lat,
      'dropoffLng': d.dropoff.lng,
      'dropoffAddress': d.dropoff.label,
      'pricePerRide': d.pricePerRide,
      'paymentMethod': d.cash ? 'CASH' : 'WALLET',
    });
    final route = DailyRoute(
      id: '${j['routeId']}',
      passengerId: d.passengerId.trim(),
      days: d.days,
      time: d.time,
      pricePerRide: d.pricePerRide,
      status: '${j['status'] ?? 'ACTIVE'}',
      pickup: d.pickup.label,
      dropoff: d.dropoff.label,
    );
    final all = await _read(_routesKey)..add(_routeJson(route));
    await _write(_routesKey, all);
    return route;
  }

  @override
  Future<DailyRoute> pauseRoute(String id, DateTime? resumeDate) async {
    final j = await _api.patch('/api/driver/daily-routes/$id/pause', body: {
      if (resumeDate != null) 'resumeDate': resumeDate.toUtc().toIso8601String(),
    });
    return _updateRoute(id, '${j['status'] ?? 'PAUSED'}');
  }

  @override
  Future<DailyRoute> resumeRoute(String id) async {
    final j = await _api.patch('/api/driver/daily-routes/$id/resume');
    return _updateRoute(id, '${j['status'] ?? 'ACTIVE'}');
  }

  @override
  Future<DailyRoute> cancelRoute(String id, String reason) async {
    final j = await _api.delete('/api/driver/daily-routes/$id', body: {'reason': reason});
    return _updateRoute(id, '${j['status'] ?? 'CANCELLED'}');
  }
}

class IntercityFakeDataSource implements IntercityRemoteDataSource {
  IntercityFakeDataSource(this._fake);
  final FakeBackend _fake;

  final _offers = <IntercityOffer>[];
  final _routes = <DailyRoute>[];
  int _seq = 0;

  @override
  Future<List<IntercityOffer>> offers() async => _offers.reversed.toList();

  @override
  Future<List<DailyRoute>> routes() async => _routes.reversed.toList();

  IntercityOffer _set(String id, String status) {
    final i = _offers.indexWhere((o) => o.id == id);
    return _offers[i] = _offers[i].withStatus(status);
  }

  DailyRoute _setRoute(String id, String status) {
    final i = _routes.indexWhere((r) => r.id == id);
    return _routes[i] = _routes[i].withStatus(status);
  }

  @override
  Future<IntercityOffer> publish(OfferDraft d) async {
    await _fake.latency(0.6);
    final o = IntercityOffer(
      id: 'o${++_seq}', number: 'T-$_seq', origin: d.origin.city, destination: d.destination.city,
      departure: d.departure, seats: d.seats, pricePerSeat: d.pricePerSeat, status: 'PUBLISHED',
    );
    _offers.add(o);
    return o;
  }

  @override
  Future<IntercityOffer> start(String id) async => _set(id, 'IN_PROGRESS');

  @override
  Future<IntercityOffer> complete(String id) async => _set(id, 'COMPLETED');

  @override
  Future<IntercityOffer> cancel(String id, String reason) async => _set(id, 'CANCELLED');

  @override
  Future<DailyRoute> createRoute(RouteDraft d) async {
    await _fake.latency(0.6);
    final r = DailyRoute(
      id: 'r${++_seq}', passengerId: d.passengerId, days: d.days, time: d.time, pricePerRide: d.pricePerRide,
      status: 'ACTIVE', pickup: d.pickup.label, dropoff: d.dropoff.label,
    );
    _routes.add(r);
    return r;
  }

  @override
  Future<DailyRoute> pauseRoute(String id, DateTime? resumeDate) async => _setRoute(id, 'PAUSED');

  @override
  Future<DailyRoute> resumeRoute(String id) async => _setRoute(id, 'ACTIVE');

  @override
  Future<DailyRoute> cancelRoute(String id, String reason) async => _setRoute(id, 'CANCELLED');
}
