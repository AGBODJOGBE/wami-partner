import 'dart:async';

import 'package:wami_core/wami_core.dart';

import '../../../../shared/location_service.dart';
import '../../../../shared/realtime_client.dart';
import '../../../../shared/session_store.dart';
import '../../domain/entities/fare.dart';
import '../../domain/entities/mission.dart';

abstract interface class MissionsRemoteDataSource {
  Future<DriverDay> day();
  Future<FarePolicy> farePolicy();
  Future<DriverDay> setOnline(bool online);
  Stream<MissionOffer> offers();
  Future<ActiveMission?> currentMission();
  Stream<String> cancellations();
  Future<ActiveMission> accept(String id);
  Future<void> decline(String id, String? reason);
  Future<ActiveMission> arrived(String id);
  Future<ActiveMission> start(String id, String code);
  Future<ActiveMission> pause(String id);
  Future<ActiveMission> resume(String id);
  Future<ActiveMission> confirmPickup(String id, bool photoTaken, String? photoPath);
  Future<MissionReceipt> complete(String id);
  Future<MissionReceipt> handover(String id, String code, PaymentMode collectedWith, String? photoPath);
  Future<void> rate(String id, int stars);
}

int _int(Object? v) => v is num ? v.round() : 0;
double _dbl(Object? v) => v is num ? v.toDouble() : 0;
DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;

/// Le serveur donne parfois un taux en pourcentage (92) et parfois en fraction (0,92).
double _rate(Object? v) {
  final d = _dbl(v);
  return d > 1 ? d / 100 : d;
}

PaymentMode _payment(Object? v) => switch (v) {
      'CASH' => PaymentMode.cash,
      'MOBILE_MONEY' => PaymentMode.mobileMoney,
      _ => PaymentMode.wallet,
    };

/// Routes du serveur WAMI : courses (`/api/driver/rides`), livraisons (`/api/driver/delivery`),
/// statut (`/api/drivers/status`) et temps réel (Socket.io).
///
/// Écarts avec le serveur, gérés ici :
/// - les propositions n'existent que par socket (`ride:new_request`, `delivery_b2c:new_request`),
///   sans nom ni note du client ;
/// - refuser une proposition n'a pas de route utilisable (la route de refus des courses répond
///   401 en permanence) : on l'ignore localement, le serveur passe au chauffeur suivant à l'expiration ;
/// - une course ne demande aucun code au départ ; seule la livraison utilise le code du destinataire (6 chiffres) ;
/// - la politique de tarif n'est pas exposée : attente et pause sont calculées par le serveur.
class MissionsApiDataSource implements MissionsRemoteDataSource {
  MissionsApiDataSource(this._api, this._rt, this._loc, this._session);

  final ApiClient _api;
  final RealtimeClient _rt;
  final LocationService _loc;
  final SessionStore _session;

  /// Commission affichée sur la proposition (estimation, le serveur reste la référence).
  static const _estimatedCommission = 0.15;
  static const _acceptSeconds = 30;

  final _kinds = <String, MissionKind>{};
  final _offers = <String, MissionOffer>{};
  ActiveMission? _current;
  String? _vehicleId;

  Timer? _heartbeat;
  Timer? _gpsTimer;
  String? _trackedId;
  LatLng? _prev;
  double _meters = 0;
  StreamSubscription<Map<String, dynamic>>? _rideSub;
  StreamSubscription<Map<String, dynamic>>? _deliverySub;
  MissionOffer? _lastOffer;
  DateTime? _lastOfferAt;
  final _offerSink = StreamController<MissionOffer>.broadcast();

  // ── Journée et disponibilité ──

  @override
  Future<DriverDay> day() async {
    final p = await _api.get('/api/drivers/profile');
    final online = const {'AVAILABLE', 'BUSY'}.contains(p['status']);
    final stats = (p['stats'] as Map<String, dynamic>?) ?? const {};
    if (online) _startPresence();

    var earnings = 0;
    var count = 0;
    try {
      final h = await _api.get('/api/drivers/rides', query: {'status': 'COMPLETED'});
      final now = DateTime.now();
      for (final r in ((h['rides'] as List<dynamic>?) ?? const []).cast<Map<String, dynamic>>()) {
        final at = _date(r['completedAt']);
        if (at != null && at.year == now.year && at.month == now.month && at.day == now.day) {
          earnings += _int(r['driverEarnings']);
          count++;
        }
      }
    } on Exception {
      // Le résumé du jour reste affichable sans l'historique.
    }
    return DriverDay(
      online: online,
      onlineSince: online ? DateTime.now() : null,
      earnings: earnings,
      missions: count,
      rating: _dbl(stats['averageRating'] ?? p['rating']),
      acceptanceRate: _rate(stats['acceptanceRate']),
    );
  }

  @override
  Future<FarePolicy> farePolicy() async => const FarePolicy(commissionRate: _estimatedCommission);

  @override
  Future<DriverDay> setOnline(bool online) async {
    if (online) {
      final pos = await _loc.current();
      if (pos == null) {
        throw const BusinessRuleException('no_location', 'Activez la localisation pour passer en ligne.');
      }
      final vehicleId = await _vehicle().then<String?>((v) => v, onError: (_) => null);
      await _api.patch('/api/drivers/status', body: {
        'status': 'ONLINE',
        'latitude': pos.lat,
        'longitude': pos.lng,
        if (vehicleId != null) 'vehicleId': vehicleId,
      });
      _startPresence();
    } else {
      await _api.patch('/api/drivers/status', body: {'status': 'OFFLINE'});
      _stopPresence();
    }
    final d = await day();
    return d.copyWith(online: online, onlineSince: online ? DateTime.now() : null);
  }

  /// Socket + battement de présence (le serveur oublie le chauffeur après 90 s sans signal).
  void _startPresence() {
    _rt.connect();
    _listenRequests();
    _heartbeat ??= Timer.periodic(const Duration(seconds: 30), (_) => _beat());
    _beat();
  }

  Future<void> _beat() async {
    if (_session.identity == null) return _stopPresence();
    final pos = await _loc.current();
    if (pos != null) _rt.heartbeat(pos.lat, pos.lng);
  }

  void _stopPresence() {
    _heartbeat?.cancel();
    _heartbeat = null;
    _rideSub?.cancel();
    _deliverySub?.cancel();
    _rideSub = _deliverySub = null;
    _stopTracking();
    _rt.disconnect();
  }

  // ── Propositions (socket) ──

  void _listenRequests() {
    _rideSub ??= _rt.rideRequests.listen((m) => _emit(_rideOffer(m)));
    _deliverySub ??= _rt.deliveryRequests.listen((m) => _emit(_deliveryOffer(m)));
  }

  void _emit(MissionOffer? o) {
    if (o == null || _current != null) return;
    _offers[o.id] = o;
    _lastOffer = o;
    _lastOfferAt = DateTime.now();
    _offerSink.add(o);
  }

  @override
  Stream<MissionOffer> offers() async* {
    // Le serveur rejoue la proposition en cours à la connexion : on la rend à l'écoute tardive.
    final last = _lastOffer;
    final at = _lastOfferAt;
    if (last != null && at != null && DateTime.now().difference(at).inSeconds < _acceptSeconds - 5) yield last;
    yield* _offerSink.stream;
  }

  Stop _stop(Object? j, String fallback, {String? contact}) {
    final m = j is Map ? j : const {};
    final a = (m['address'] as String?)?.trim() ?? '';
    return Stop(label: a.isEmpty ? fallback : a, address: '', contactName: contact);
  }

  MissionOffer? _rideOffer(Map<String, dynamic> m) {
    final id = m['rideId'] as String?;
    if (id == null) return null;
    _kinds[id] = MissionKind.ride;
    final price = _int(m['estimatedPrice']);
    final pick = m['pickup'];
    final pos = _loc.last;
    final toPickup = (pos != null && pick is Map && pick['latitude'] is num && pick['longitude'] is num)
        ? haversineMeters(pos, (lat: _dbl(pick['latitude']), lng: _dbl(pick['longitude']))) / 1000
        : 0.0;
    return MissionOffer(
      id: id,
      kind: MissionKind.ride,
      pickup: _stop(pick, 'Point de départ'),
      dropoff: _stop(m['dropoff'], 'Destination'),
      distanceToPickupKm: toPickup,
      tripKm: _dbl(m['estimatedDistanceKm']),
      tripMinutes: _int(m['estimatedDurationMin']),
      clientPrice: price,
      netEarning: (price * (1 - _estimatedCommission)).round(),
      payment: _payment(m['paymentMethod']),
      customerName: 'Client',
      customerRating: 0,
      acceptSeconds: _acceptSeconds,
    );
  }

  MissionOffer? _deliveryOffer(Map<String, dynamic> m) {
    final id = m['orderId'] as String?;
    if (id == null) return null;
    _kinds[id] = MissionKind.parcel;
    final price = _int(m['estimatedPrice']);
    final pick = m['pickup'];
    final pos = _loc.last;
    final toPickup = (pos != null && pick is Map && pick['latitude'] is num && pick['longitude'] is num)
        ? haversineMeters(pos, (lat: _dbl(pick['latitude']), lng: _dbl(pick['longitude']))) / 1000
        : 0.0;
    final recipient = m['recipient'] is Map ? m['recipient'] as Map : const {};
    return MissionOffer(
      id: id,
      kind: MissionKind.parcel,
      pickup: _stop(pick, 'Point de collecte'),
      dropoff: _stop(m['dropoff'], 'Destinataire', contact: recipient['name'] as String?),
      distanceToPickupKm: toPickup,
      tripKm: _dbl(m['estimatedDistanceKm']),
      tripMinutes: _int(m['estimatedDurationMin']),
      clientPrice: price,
      netEarning: (price * (1 - _estimatedCommission)).round(),
      payment: _payment(m['paymentMethod']),
      customerName: 'Expéditeur',
      customerRating: 0,
      orderNumber: m['orderNumber'] as String?,
      acceptSeconds: _acceptSeconds,
    );
  }

  @override
  Future<void> decline(String id, String? reason) async {
    _offers.remove(id);
    if (_lastOffer?.id == id) _lastOffer = null;
  }

  // ── Véhicule ──

  Future<String> _vehicle() async {
    final cached = _vehicleId;
    if (cached != null) return cached;
    final p = await _api.get('/api/drivers/profile');
    var id = p['assignedVehicleId'] as String?;
    if (id == null) {
      final v = await _api.get('/api/drivers/vehicle');
      id = v['id'] as String?;
    }
    if (id == null) throw const BusinessRuleException('no_vehicle', 'Aucun véhicule actif sur votre compte.');
    return _vehicleId = id;
  }

  // ── Courses ──

  MissionStage _rideStage(Object? status) => switch (status) {
        'DRIVER_ASSIGNED' || 'DRIVER_EN_ROUTE' => MissionStage.toPickup,
        'DRIVER_ARRIVED' => MissionStage.atPickup,
        'IN_PROGRESS' => MissionStage.inProgress,
        'PAUSED' => MissionStage.paused,
        'COMPLETED' || 'RATED' => MissionStage.completed,
        _ => MissionStage.cancelled,
      };

  MissionOffer _offerFromRide(Map<String, dynamic> j, MissionOffer? base) {
    final p = j['passenger'] is Map ? j['passenger'] as Map : const {};
    final name = '${p['firstName'] ?? ''} ${p['lastName'] ?? ''}'.trim();
    final price = _int(j['estimatedPrice']);
    final offer = base ??
        MissionOffer(
          id: j['rideId'] as String,
          kind: MissionKind.ride,
          pickup: _stop(j['pickup'], 'Point de départ'),
          dropoff: _stop(j['dropoff'], 'Destination'),
          distanceToPickupKm: 0,
          tripKm: _dbl(j['estimatedDistanceKm']),
          tripMinutes: _int(j['estimatedDurationMin']),
          clientPrice: price,
          netEarning: j['driverEarnings'] is num ? _int(j['driverEarnings']) : (price * (1 - _estimatedCommission)).round(),
          payment: _payment(j['paymentMethod']),
          customerName: 'Client',
          customerRating: 0,
        );
    return name.isEmpty ? offer : offer.copyWith(customerName: name);
  }

  /// Relit la course sur le serveur : étape, heures d'arrivée, de départ et durée des pauses.
  Future<ActiveMission> _loadRide(String id, MissionOffer? base) async {
    final j = await _api.get('/api/driver/rides/$id');
    _kinds[id] = MissionKind.ride;
    return _current = ActiveMission(
      offer: _offerFromRide({...j, 'rideId': id}, base ?? _current?.offer),
      stage: _rideStage(j['status']),
      arrivedAt: _date(j['arrivedAt']),
      startedAt: _date(j['startedAt']),
      pausedAt: _date(j['pausedAt']),
      pausedBefore: Duration(seconds: _int(j['totalPausedSeconds'])),
    );
  }

  @override
  Future<ActiveMission> accept(String id) async {
    final base = _offers.remove(id);
    final kind = _kinds[id] ?? MissionKind.ride;
    _lastOffer = null;
    if (kind.isDelivery) {
      final j = await _api.patch('/api/driver/delivery/$id/accept');
      _rt.joinOrder(id);
      final recipient = j['recipient'] is Map ? j['recipient'] as Map : const {};
      final offer = (base ?? _offerFromOrder(j, id)).copyWith(
        pickup: _stop(j['pickup'], 'Point de collecte', contact: (j['pickup'] as Map?)?['contactName'] as String?),
        dropoff: _stop(j['dropoff'], 'Destinataire', contact: recipient['name'] as String?),
        parcelSize: _parcelSize(j['parcel']),
        fragile: (j['parcel'] as Map?)?['type'] == 'FRAGILE',
      );
      _current = ActiveMission(offer: offer, stage: MissionStage.toPickup);
    } else {
      await _api.patch('/api/driver/rides/$id/accept', body: {'vehicleId': await _vehicle()});
      _rt.joinRide(id);
      await _loadRide(id, base);
    }
    _startTracking(id);
    return _current!;
  }

  String? _parcelSize(Object? parcel) {
    if (parcel is! Map) return null;
    return switch (parcel['type']) {
      'DOCUMENT' => 'document',
      'SMALL_PARCEL' => 'petit',
      'MEDIUM_PARCEL' => 'moyen',
      'LARGE_PARCEL' => 'grand',
      'FRAGILE' => 'fragile',
      'FOOD' => 'repas',
      _ => null,
    };
  }

  MissionOffer _offerFromOrder(Map<String, dynamic> j, String id) {
    final price = _int(j['estimatedPrice'] ?? (j['pricing'] as Map?)?['estimatedPrice']);
    return MissionOffer(
      id: id,
      kind: MissionKind.parcel,
      pickup: _stop(j['pickup'], 'Point de collecte'),
      dropoff: _stop(j['dropoff'], 'Destinataire'),
      distanceToPickupKm: 0,
      tripKm: 0,
      tripMinutes: 0,
      clientPrice: price,
      netEarning: (price * (1 - _estimatedCommission)).round(),
      payment: _payment(j['paymentMethod']),
      customerName: 'Expéditeur',
      customerRating: 0,
      orderNumber: j['orderNumber'] as String?,
    );
  }

  ActiveMission _require(String id) {
    final m = _current;
    if (m == null || m.offer.id != id) throw const BusinessRuleException('unavailable', 'Mission introuvable.');
    return m;
  }

  @override
  Future<ActiveMission> arrived(String id) async {
    final m = _require(id);
    if (m.offer.kind.isDelivery) {
      await _api.patch('/api/driver/delivery/$id/pickup-arrival');
      return _current = m.copyWith(stage: MissionStage.atPickup, arrivedAt: DateTime.now());
    }
    await _api.patch('/api/driver/rides/$id/arrived');
    return _loadRide(id, m.offer);
  }

  @override
  Future<ActiveMission> start(String id, String code) async {
    final pos = _loc.last;
    await _api.patch('/api/driver/rides/$id/start', body: {
      if (pos != null) 'lat': pos.lat,
      if (pos != null) 'lng': pos.lng,
    });
    _meters = 0;
    _prev = null;
    return _loadRide(id, _current?.offer);
  }

  @override
  Future<ActiveMission> pause(String id) async {
    await _api.patch('/api/driver/rides/$id/pause');
    return _loadRide(id, _current?.offer);
  }

  @override
  Future<ActiveMission> resume(String id) async {
    await _api.patch('/api/driver/rides/$id/resume');
    return _loadRide(id, _current?.offer);
  }

  @override
  Future<MissionReceipt> complete(String id) async {
    final before = await _api.get('/api/driver/rides/$id');
    final started = _date(before['startedAt']);
    final paused = _int(before['totalPausedSeconds']);
    final seconds = started == null
        ? _int(before['estimatedDurationMin']) * 60
        : DateTime.now().difference(started).inSeconds - paused;
    // Trajet réel suivi par GPS ; à défaut, l'estimation du serveur.
    final meters = _meters >= 100 ? _meters : _dbl(before['estimatedDistanceKm']) * 1000;
    final r = await _api.patch('/api/driver/rides/$id/complete', body: {
      'actualDistanceMeters': meters.round(),
      'actualDurationSeconds': seconds < 1 ? 1 : seconds,
    });
    _stopTracking();
    var waiting = 0;
    try {
      final after = await _api.get('/api/driver/rides/$id');
      waiting = _int(after['waitingFeeFcfa']);
    } on Exception {
      waiting = 0;
    }
    final total = _int(r['finalPrice']);
    final payment = _payment(r['paymentMethod']);
    _current = null;
    return MissionReceipt(
      kind: MissionKind.ride,
      clientPrice: (total - waiting).clamp(0, total).toInt(),
      waitingFee: waiting,
      pauseFee: 0,
      commission: _int(r['platformCommission']),
      payment: payment,
    );
  }

  // ── Livraisons ──

  @override
  Future<ActiveMission> confirmPickup(String id, bool photoTaken, String? photoPath) async {
    final m = _require(id);
    if (photoPath == null) throw const BusinessRuleException('no_photo', 'Prenez une photo du colis.');
    await _api.patchForm('/api/driver/delivery/$id/pickup-photo', files: {'photo': photoPath});
    return _current = m.copyWith(stage: MissionStage.inProgress, startedAt: DateTime.now());
  }

  @override
  Future<MissionReceipt> handover(String id, String code, PaymentMode collectedWith, String? photoPath) async {
    final m = _require(id);
    if (photoPath == null) throw const BusinessRuleException('no_photo', 'Prenez la photo de remise.');
    final order = await _api.get('/api/driver/delivery/$id');
    if (order['status'] == 'IN_TRANSIT') await _api.patch('/api/driver/delivery/$id/delivery-arrival');
    await _api.patch('/api/driver/delivery/$id/validate-otp', body: {'otpCode': code});
    await _api.patchForm(
      '/api/driver/delivery/$id/delivery-photo',
      fields: {'finalPrice': '${m.offer.clientPrice}'},
      files: {'photo': photoPath},
    );
    _stopTracking();
    var price = m.offer.clientPrice;
    var commission = 0;
    var payment = m.offer.payment;
    try {
      final done = await _api.get('/api/driver/delivery/$id');
      final pricing = done['pricing'] is Map ? done['pricing'] as Map : const {};
      if (pricing['finalPrice'] is num) price = _int(pricing['finalPrice']);
      commission = _int(pricing['platformCommission']);
      payment = _payment(done['paymentMethod']);
    } on Exception {
      commission = (price * _estimatedCommission).round();
    }
    _current = null;
    return MissionReceipt(
      kind: m.offer.kind,
      clientPrice: price,
      waitingFee: 0,
      pauseFee: 0,
      commission: commission,
      payment: payment,
    );
  }

  @override
  Future<void> rate(String id, int stars) async {
    if (_kinds[id] != MissionKind.ride) return; // pas de note du client pour les livraisons
    await _api.post('/api/driver/rides/$id/rating', body: {'score': stars});
  }

  // ── Reprise et annulation ──

  @override
  Future<ActiveMission?> currentMission() async {
    final j = await _api.get('/api/driver/rides/current');
    final id = j['rideId'] as String?;
    if (id != null) {
      _rt.connect();
      _rt.joinRide(id);
      final m = await _loadRide(id, null);
      if (m.stage == MissionStage.completed || m.stage == MissionStage.cancelled) return _current = null;
      _startTracking(id);
      return m;
    }
    return _currentDelivery();
  }

  Future<ActiveMission?> _currentDelivery() async {
    final list = await _api.get('/api/driver/delivery');
    final orders = list['items'] ?? list.values.whereType<List<dynamic>>().firstOrNull;
    if (orders is! List) return null;
    const active = {'DRIVER_ASSIGNED', 'PICKUP_IN_PROGRESS', 'IN_TRANSIT', 'DELIVERY_IN_PROGRESS'};
    for (final o in orders.whereType<Map<String, dynamic>>()) {
      final status = o['status'];
      if (!active.contains(status)) continue;
      final id = (o['id'] ?? o['orderId']) as String;
      final j = await _api.get('/api/driver/delivery/$id');
      _kinds[id] = MissionKind.parcel;
      final recipient = j['recipient'] is Map ? j['recipient'] as Map : const {};
      final offer = _offerFromOrder(j, id).copyWith(
        dropoff: _stop(j['dropoff'], 'Destinataire', contact: recipient['name'] as String?),
        parcelSize: _parcelSize(j['parcel']),
      );
      _rt.connect();
      _rt.joinOrder(id);
      _startTracking(id);
      return _current = ActiveMission(
        offer: offer,
        stage: switch (status) {
          'DRIVER_ASSIGNED' => MissionStage.toPickup,
          'PICKUP_IN_PROGRESS' => MissionStage.atPickup,
          _ => MissionStage.inProgress,
        },
      );
    }
    return null;
  }

  @override
  Stream<String> cancellations() => _rt.cancellations
      .map((m) => m['rideId'] as String?)
      .where((id) => id != null && id == _current?.offer.id)
      .cast<String>()
      .map((id) {
    _current = null;
    _stopTracking();
    return id;
  });

  // ── Suivi GPS pendant une mission ──

  void _startTracking(String id) {
    _stopTracking();
    _trackedId = id;
    _meters = 0;
    _prev = null;
    _gpsTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_session.identity == null) return _stopTracking();
      final fix = await _loc.currentFix();
      final tracked = _trackedId;
      if (fix == null || tracked == null) return;
      final here = (lat: fix.latitude, lng: fix.longitude);
      final prev = _prev;
      if (prev != null && _current?.stage == MissionStage.inProgress) _meters += haversineMeters(prev, here);
      _prev = here;
      _rt.gps(tracked, lat: fix.latitude, lng: fix.longitude, heading: fix.heading, speed: fix.speed, accuracy: fix.accuracy);
    });
  }

  void _stopTracking() {
    _gpsTimer?.cancel();
    _gpsTimer = null;
    _trackedId = null;
  }
}

/// Backend simulé : propose une mission toutes les quelques secondes en ligne,
/// en alternant course, colis et repas. Code de démo du destinataire : 482193 (la course ne demande pas de code).
class MissionsFakeDataSource implements MissionsRemoteDataSource {
  MissionsFakeDataSource(this._fake, {this.offerDelay = const Duration(seconds: 4)});
  final FakeBackend _fake;
  final Duration offerDelay;

  static const demoCode = '482193';
  static const _policy = FarePolicy();

  DriverDay _day = const DriverDay(
    online: false,
    earnings: 12450,
    missions: 8,
    rating: 4.9,
    acceptanceRate: 0.92,
    hotZone: 'Dantokpa',
  );
  final _offers = <String, MissionOffer>{};
  ActiveMission? _active;
  int _seq = 0;

  @override
  Future<DriverDay> day() async {
    await _fake.latency(0.4);
    return _day;
  }

  @override
  Future<FarePolicy> farePolicy() async => _policy;

  @override
  Future<DriverDay> setOnline(bool online) async {
    await _fake.latency(0.5);
    return _day = _day.copyWith(online: online, onlineSince: online ? DateTime.now() : null);
  }

  @override
  Stream<MissionOffer> offers() async* {
    while (true) {
      await Future<void>.delayed(offerDelay);
      if (!_day.online || _active != null) continue;
      final o = _next();
      _offers[o.id] = o;
      yield o;
      // Laisse le temps de répondre avant la proposition suivante.
      await Future<void>.delayed(Duration(seconds: o.acceptSeconds));
    }
  }

  MissionOffer _next() {
    final kind = MissionKind.values[_seq % 3];
    final id = 'M${++_seq}';
    return switch (kind) {
      MissionKind.ride => MissionOffer(
          id: id,
          kind: kind,
          pickup: const Stop(label: 'Marché Dantokpa', address: 'Porte 3', contactName: '[Nom du client]', note: 'Je porte un tee-shirt rouge'),
          dropoff: const Stop(label: 'Fidjrossè Plage', address: 'Cotonou'),
          distanceToPickupKm: 1.2,
          tripKm: 6.8,
          tripMinutes: 2, // durée courte pour la démo
          clientPrice: 1700,
          netEarning: 1445,
          payment: PaymentMode.wallet,
          customerName: '[Nom du client]',
          customerRating: 4.8,
        ),
      MissionKind.parcel => MissionOffer(
          id: id,
          kind: kind,
          pickup: const Stop(label: 'Cadjèhoun', address: 'Bâtiment bleu', contactName: '[Expéditeur]'),
          dropoff: const Stop(label: 'Akpakpa', address: 'Rue [N]', contactName: '[Destinataire]'),
          distanceToPickupKm: 0.9,
          tripKm: 5.4,
          tripMinutes: 2,
          clientPrice: 1000,
          netEarning: 850,
          payment: PaymentMode.wallet,
          customerName: '[Expéditeur]',
          customerRating: 4.7,
          cashToCollect: 15000,
          parcelSize: 'moyen',
          fragile: true,
        ),
      MissionKind.meal => MissionOffer(
          id: id,
          kind: kind,
          pickup: const Stop(label: '[Restaurant A]', address: 'Haie Vive'),
          dropoff: const Stop(label: 'Akpakpa', address: 'Rue [N]', contactName: '[Client]'),
          distanceToPickupKm: 0.35,
          tripKm: 4.1,
          tripMinutes: 2,
          clientPrice: 800,
          netEarning: 680,
          payment: PaymentMode.wallet,
          customerName: '[Client]',
          customerRating: 4.6,
          orderNumber: '482',
          items: const ['2 × Poulet braisé, attiéké', '1 × Jus de bissap'],
        ),
    };
  }

  ActiveMission _require(String id) {
    final m = _active;
    if (m == null || m.offer.id != id) throw const BusinessRuleException('unavailable', 'Mission introuvable.');
    return m;
  }

  @override
  Future<ActiveMission> accept(String id) async {
    await _fake.latency(0.6);
    final o = _offers.remove(id);
    if (o == null) throw const BusinessRuleException('unavailable', 'Cette mission a été attribuée à un autre partenaire.');
    return _active = ActiveMission(offer: o, stage: MissionStage.toPickup);
  }

  @override
  Future<void> decline(String id, String? reason) async {
    _offers.remove(id);
  }

  @override
  Future<ActiveMission> arrived(String id) async {
    await _fake.latency(0.4);
    return _active = _require(id).copyWith(stage: MissionStage.atPickup, arrivedAt: DateTime.now());
  }

  @override
  Future<ActiveMission> start(String id, String code) async {
    await _fake.latency(0.6);
    final m = _require(id);
    return _active = m.copyWith(stage: MissionStage.inProgress, startedAt: DateTime.now());
  }

  @override
  Future<ActiveMission> pause(String id) async {
    await _fake.latency(0.3);
    return _active = _require(id).copyWith(stage: MissionStage.paused, pausedAt: DateTime.now());
  }

  @override
  Future<ActiveMission> resume(String id) async {
    await _fake.latency(0.3);
    final m = _require(id);
    final extra = m.pausedAt == null ? Duration.zero : DateTime.now().difference(m.pausedAt!);
    return _active = m.copyWith(stage: MissionStage.inProgress, clearPausedAt: true, pausedBefore: m.pausedBefore + extra);
  }

  @override
  Future<ActiveMission> confirmPickup(String id, bool photoTaken, String? photoPath) async {
    await _fake.latency(0.6);
    return _active = _require(id).copyWith(stage: MissionStage.inProgress, startedAt: DateTime.now());
  }

  MissionReceipt _finish(ActiveMission m) {
    final r = MissionReceipt.compute(m, _policy, DateTime.now());
    _active = null;
    _day = _day.copyWith(earnings: _day.earnings + r.net, missions: _day.missions + 1);
    return r;
  }

  @override
  Future<MissionReceipt> complete(String id) async {
    await _fake.latency(0.8);
    return _finish(_require(id));
  }

  @override
  Future<MissionReceipt> handover(String id, String code, PaymentMode collectedWith, String? photoPath) async {
    await _fake.latency(0.8);
    final m = _require(id);
    if (code != demoCode) throw const BusinessRuleException('bad_code', 'Code du destinataire incorrect. Démo : 482193.');
    return _finish(m);
  }

  @override
  Future<void> rate(String id, int stars) => _fake.latency(0.3);

  @override
  Future<ActiveMission?> currentMission() async => _active;

  @override
  Stream<String> cancellations() => const Stream.empty();
}
