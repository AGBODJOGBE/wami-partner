import 'package:wami_core/wami_core.dart';

import '../../domain/entities/rental.dart';

abstract interface class RentalRemoteDataSource {
  Future<List<Listing>> listings(String establishmentId);
  Future<Listing> setRented(String listingId, bool rented);
  Future<List<VisitRequest>> visits(String establishmentId);
  Future<VisitRequest> acceptVisit(String visitId);
  Future<VisitRequest> declineVisit(String visitId);
  Future<VisitRequest> proposeVisit(String visitId, DateTime slot);
  Future<List<AvailabilityWindow>> availability(String establishmentId);
  Future<List<AvailabilityWindow>> saveAvailability(String establishmentId, List<AvailabilityWindow> windows);
}

Listing _listing(Map<String, dynamic> j) => Listing(
      id: j['id'] as String,
      title: j['title'] as String,
      district: j['district'] as String,
      monthlyRent: j['monthly_rent'] as int,
      rooms: j['rooms'] as int,
      rented: j['rented'] as bool? ?? false,
    );

VisitRequest _visit(Map<String, dynamic> j) => VisitRequest(
      id: j['id'] as String,
      listingId: j['listing_id'] as String,
      listingTitle: j['listing_title'] as String,
      visitorName: j['visitor_name'] as String,
      requestedAt: DateTime.parse(j['requested_at'] as String),
      status: VisitStatus.values.byName(j['status'] as String),
      proposedAt: j['proposed_at'] == null ? null : DateTime.parse(j['proposed_at'] as String),
    );

List<AvailabilityWindow> _windows(Map<String, dynamic> j) => [
      for (final w in (j['items'] as List<dynamic>).cast<Map<String, dynamic>>())
        AvailabilityWindow(weekday: w['weekday'] as int, startHour: w['start_hour'] as int, endHour: w['end_hour'] as int),
    ];

/// Endpoints à valider.
class RentalApiDataSource implements RentalRemoteDataSource {
  const RentalApiDataSource(this._api);
  final ApiClient _api;

  @override
  Future<List<Listing>> listings(String establishmentId) async {
    final j = await _api.get('/v1/business/establishments/$establishmentId/listings');
    return [for (final l in (j['items'] as List<dynamic>).cast<Map<String, dynamic>>()) _listing(l)];
  }

  @override
  Future<Listing> setRented(String listingId, bool rented) async =>
      _listing(await _api.put('/v1/business/listings/$listingId', body: {'rented': rented}));

  @override
  Future<List<VisitRequest>> visits(String establishmentId) async {
    final j = await _api.get('/v1/business/establishments/$establishmentId/visits');
    return [for (final v in (j['items'] as List<dynamic>).cast<Map<String, dynamic>>()) _visit(v)];
  }

  @override
  Future<VisitRequest> acceptVisit(String visitId) async => _visit(await _api.post('/v1/business/visits/$visitId/accept'));

  @override
  Future<VisitRequest> declineVisit(String visitId) async => _visit(await _api.post('/v1/business/visits/$visitId/decline'));

  @override
  Future<VisitRequest> proposeVisit(String visitId, DateTime slot) async =>
      _visit(await _api.post('/v1/business/visits/$visitId/propose', body: {'slot': slot.toIso8601String()}));

  @override
  Future<List<AvailabilityWindow>> availability(String establishmentId) async =>
      _windows(await _api.get('/v1/business/establishments/$establishmentId/visit-availability'));

  @override
  Future<List<AvailabilityWindow>> saveAvailability(String establishmentId, List<AvailabilityWindow> windows) async =>
      _windows(await _api.put('/v1/business/establishments/$establishmentId/visit-availability', body: {
        'items': [for (final w in windows) {'weekday': w.weekday, 'start_hour': w.startHour, 'end_hour': w.endHour}],
      }));
}

/// Démo : 3 biens, 2 demandes de visite en attente, disponibilités mercredi et samedi.
class RentalFakeDataSource implements RentalRemoteDataSource {
  RentalFakeDataSource(this._fake) {
    final now = DateTime.now();
    DateTime at(int days, int hour) => DateTime(now.year, now.month, now.day + days, hour);
    _visits.addAll([
      VisitRequest(id: 'v1', listingId: 'l1', listingTitle: 'Appartement B2 · 3 pièces', visitorName: 'Fabrice Z.', requestedAt: at(1, 10)),
      VisitRequest(id: 'v2', listingId: 'l2', listingTitle: 'Studio meublé', visitorName: 'Prisca M.', requestedAt: at(2, 17)),
      VisitRequest(id: 'v3', listingId: 'l1', listingTitle: 'Appartement B2 · 3 pièces', visitorName: 'Hervé G.', requestedAt: at(3, 9), status: VisitStatus.accepted),
    ]);
  }

  final FakeBackend _fake;
  final List<VisitRequest> _visits = [];
  final List<Listing> _listings = [
    const Listing(id: 'l1', title: 'Appartement B2 · 3 pièces', district: 'Akpakpa', monthlyRent: 150000, rooms: 3),
    const Listing(id: 'l2', title: 'Studio meublé', district: 'Akpakpa', monthlyRent: 85000, rooms: 1),
    const Listing(id: 'l3', title: 'Villa 4 chambres', district: 'Haie Vive', monthlyRent: 450000, rooms: 4, rented: true),
  ];
  List<AvailabilityWindow> _windows = const [
    AvailabilityWindow(weekday: 3, startHour: 16, endHour: 19),
    AvailabilityWindow(weekday: 6, startHour: 9, endHour: 13),
  ];

  VisitRequest _updateVisit(String id, VisitRequest Function(VisitRequest v) change) {
    final i = _visits.indexWhere((v) => v.id == id);
    if (i < 0) throw const BusinessRuleException('unavailable');
    return _visits[i] = change(_visits[i]);
  }

  @override
  Future<List<Listing>> listings(String establishmentId) async {
    await _fake.latency(0.5);
    return List.of(_listings);
  }

  @override
  Future<Listing> setRented(String listingId, bool rented) async {
    await _fake.latency(0.4);
    final i = _listings.indexWhere((l) => l.id == listingId);
    if (i < 0) throw const BusinessRuleException('unavailable');
    if (rented) {
      // Un bien loué ne se visite plus : les demandes en attente sont refusées.
      for (var k = 0; k < _visits.length; k++) {
        if (_visits[k].listingId == listingId && _visits[k].status == VisitStatus.pending) {
          _visits[k] = _visits[k].copyWith(status: VisitStatus.declined);
        }
      }
    }
    return _listings[i] = _listings[i].copyWith(rented: rented);
  }

  @override
  Future<List<VisitRequest>> visits(String establishmentId) async {
    await _fake.latency(0.5);
    return List.of(_visits);
  }

  @override
  Future<VisitRequest> acceptVisit(String visitId) async {
    await _fake.latency(0.4);
    return _updateVisit(visitId, (v) => v.copyWith(status: VisitStatus.accepted));
  }

  @override
  Future<VisitRequest> declineVisit(String visitId) async {
    await _fake.latency(0.4);
    return _updateVisit(visitId, (v) => v.copyWith(status: VisitStatus.declined));
  }

  @override
  Future<VisitRequest> proposeVisit(String visitId, DateTime slot) async {
    await _fake.latency(0.4);
    return _updateVisit(visitId, (v) => v.copyWith(status: VisitStatus.proposed, proposedAt: slot));
  }

  @override
  Future<List<AvailabilityWindow>> availability(String establishmentId) async {
    await _fake.latency(0.3);
    return _windows;
  }

  @override
  Future<List<AvailabilityWindow>> saveAvailability(String establishmentId, List<AvailabilityWindow> windows) async {
    await _fake.latency(0.4);
    return _windows = List.unmodifiable(windows);
  }
}
