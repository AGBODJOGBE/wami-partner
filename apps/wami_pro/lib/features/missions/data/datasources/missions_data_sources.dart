import 'package:wami_core/wami_core.dart';

import '../../domain/entities/fare.dart';
import '../../domain/entities/mission.dart';
import '../models/mission_models.dart';

abstract interface class MissionsRemoteDataSource {
  Future<DriverDay> day();
  Future<FarePolicy> farePolicy();
  Future<DriverDay> setOnline(bool online);
  Stream<MissionOffer> offers();
  Future<ActiveMission> accept(String id);
  Future<void> decline(String id, String? reason);
  Future<ActiveMission> arrived(String id);
  Future<ActiveMission> start(String id, String code);
  Future<ActiveMission> pause(String id);
  Future<ActiveMission> resume(String id);
  Future<ActiveMission> confirmPickup(String id, bool photoTaken);
  Future<MissionReceipt> complete(String id);
  Future<MissionReceipt> handover(String id, String code, PaymentMode collectedWith);
  Future<void> rate(String id, int stars);
}

/// Endpoints à valider. Les propositions arrivent en production par WebSocket
/// (Socket.io) : ici un polling simple sert de point de départ.
class MissionsApiDataSource implements MissionsRemoteDataSource {
  const MissionsApiDataSource(this._api);
  final ApiClient _api;

  @override
  Future<DriverDay> day() async => MissionModels.day(await _api.get('/v1/partner/day'));

  @override
  Future<FarePolicy> farePolicy() async => MissionModels.policy(await _api.get('/v1/partner/fare-policy'));

  @override
  Future<DriverDay> setOnline(bool online) async =>
      MissionModels.day(await _api.put('/v1/partner/availability', body: {'online': online}));

  @override
  Stream<MissionOffer> offers() async* {
    while (true) {
      final j = await _api.get('/v1/partner/offers/next');
      if (j.isNotEmpty) yield MissionModels.offer(j);
      await Future<void>.delayed(const Duration(seconds: 4));
    }
  }

  Future<ActiveMission> _act(String id, String action, [Map<String, dynamic>? body]) async =>
      MissionModels.active(await _api.post('/v1/partner/missions/$id/$action', body: body));

  @override
  Future<ActiveMission> accept(String id) => _act(id, 'accept');

  @override
  Future<void> decline(String id, String? reason) => _api.post('/v1/partner/missions/$id/decline', body: {'reason': reason});

  @override
  Future<ActiveMission> arrived(String id) => _act(id, 'arrived');

  @override
  Future<ActiveMission> start(String id, String code) => _act(id, 'start', {'code': code});

  @override
  Future<ActiveMission> pause(String id) => _act(id, 'pause');

  @override
  Future<ActiveMission> resume(String id) => _act(id, 'resume');

  @override
  Future<ActiveMission> confirmPickup(String id, bool photoTaken) => _act(id, 'pickup', {'photo': photoTaken});

  @override
  Future<MissionReceipt> complete(String id) async =>
      MissionModels.receipt(await _api.post('/v1/partner/missions/$id/complete'));

  @override
  Future<MissionReceipt> handover(String id, String code, PaymentMode collectedWith) async => MissionModels.receipt(
        await _api.post('/v1/partner/missions/$id/handover', body: {'code': code, 'collected_with': collectedWith.name}),
      );

  @override
  Future<void> rate(String id, int stars) => _api.post('/v1/partner/missions/$id/rating', body: {'stars': stars});
}

/// Backend simulé : propose une mission toutes les quelques secondes en ligne,
/// en alternant course, colis et repas. Codes de démo : client 4821, destinataire 4821.
class MissionsFakeDataSource implements MissionsRemoteDataSource {
  MissionsFakeDataSource(this._fake, {this.offerDelay = const Duration(seconds: 4)});
  final FakeBackend _fake;
  final Duration offerDelay;

  static const demoCode = '4821';
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
    if (code != demoCode) throw const BusinessRuleException('bad_code', 'Code incorrect. Démo : 4821.');
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
  Future<ActiveMission> confirmPickup(String id, bool photoTaken) async {
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
  Future<MissionReceipt> handover(String id, String code, PaymentMode collectedWith) async {
    await _fake.latency(0.8);
    final m = _require(id);
    if (code != demoCode) throw const BusinessRuleException('bad_code', 'Code du destinataire incorrect. Démo : 4821.');
    return _finish(m);
  }

  @override
  Future<void> rate(String id, int stars) => _fake.latency(0.3);
}
