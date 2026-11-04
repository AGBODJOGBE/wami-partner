import 'package:wami_core/wami_core.dart';

import '../../../../shared/business_activity.dart';
import '../../domain/entities/establishment.dart';

abstract interface class EstablishmentsRemoteDataSource {
  Future<List<Establishment>> establishments();
  Future<Establishment> setOpen(String id, bool open);
  Future<DashboardSnapshot> dashboard(String id);
}

Establishment _establishment(Map<String, dynamic> j) => Establishment(
      id: j['id'] as String,
      name: j['name'] as String,
      activity: BusinessActivity.values.byName(j['activity'] as String),
      district: j['district'] as String? ?? '',
      open: j['open'] as bool? ?? false,
    );

/// Endpoints à valider.
class EstablishmentsApiDataSource implements EstablishmentsRemoteDataSource {
  const EstablishmentsApiDataSource(this._api);
  final ApiClient _api;

  @override
  Future<List<Establishment>> establishments() async {
    final j = await _api.get('/v1/business/me/establishments');
    return [for (final e in (j['items'] as List<dynamic>).cast<Map<String, dynamic>>()) _establishment(e)];
  }

  @override
  Future<Establishment> setOpen(String id, bool open) async =>
      _establishment(await _api.put('/v1/business/establishments/$id/open', body: {'open': open}));

  @override
  Future<DashboardSnapshot> dashboard(String id) async {
    final j = await _api.get('/v1/business/establishments/$id/dashboard');
    return DashboardSnapshot(
      revenueToday: j['revenue_today'] as int,
      activityCount: j['activity_count'] as int,
      activityLabel: j['activity_label'] as String,
      rating: (j['rating'] as num).toDouble(),
      reviewsCount: j['reviews_count'] as int,
      week: (j['week'] as List<dynamic>).cast<int>(),
      weekLabels: (j['week_labels'] as List<dynamic>).cast<String>(),
      inbox: [
        for (final i in (j['inbox'] as List<dynamic>).cast<Map<String, dynamic>>())
          InboxItem(
            title: i['title'] as String,
            subtitle: i['subtitle'] as String,
            target: InboxTarget.values.byName(i['target'] as String),
            urgent: i['urgent'] as bool? ?? false,
          ),
      ],
    );
  }
}

/// Démo : un compte qui gère les quatre familles d'activité.
/// Noms et chiffres fictifs.
class EstablishmentsFakeDataSource implements EstablishmentsRemoteDataSource {
  EstablishmentsFakeDataSource(this._fake);
  final FakeBackend _fake;

  final List<Establishment> _items = [
    const Establishment(id: 'resto-1', name: 'Le Palmier', activity: BusinessActivity.restaurant, district: 'Cadjèhoun, Cotonou', open: true),
    const Establishment(id: 'hotel-1', name: 'Hôtel Les Cocotiers', activity: BusinessActivity.hotel, district: 'Fidjrossè, Cotonou', open: true),
    const Establishment(id: 'home-1', name: 'Résidence Akpakpa', activity: BusinessActivity.apartments, district: 'Akpakpa, Cotonou', open: true),
    const Establishment(id: 'bus-1', name: 'Trans-Alibori Express', activity: BusinessActivity.busCompany, district: 'Gare de Jonquet, Cotonou', open: true),
  ];

  @override
  Future<List<Establishment>> establishments() async {
    await _fake.latency(0.5);
    return List.of(_items);
  }

  @override
  Future<Establishment> setOpen(String id, bool open) async {
    await _fake.latency(0.4);
    final i = _items.indexWhere((e) => e.id == id);
    if (i < 0) throw const BusinessRuleException('unavailable');
    return _items[i] = _items[i].copyWith(open: open);
  }

  @override
  Future<DashboardSnapshot> dashboard(String id) async {
    await _fake.latency(0.6);
    final e = _items.firstWhere((x) => x.id == id, orElse: () => throw const BusinessRuleException('unavailable'));
    const labels = ['Jeu', 'Ven', 'Sam', 'Dim', 'Lun', 'Mar', 'Mer'];
    return switch (e.activity.family) {
      ActivityFamily.food => const DashboardSnapshot(
          revenueToday: 86500,
          activityCount: 23,
          activityLabel: 'commandes',
          rating: 4.6,
          reviewsCount: 212,
          week: [64000, 91000, 118000, 102000, 58000, 71000, 86500],
          weekLabels: labels,
          inbox: [
            InboxItem(title: '2 commandes à accepter', subtitle: 'Expirent dans moins de 2 min', target: InboxTarget.activity, urgent: true),
            InboxItem(title: '1 avis sans réponse', subtitle: '3 étoiles · « Attente un peu longue »', target: InboxTarget.reviews),
          ],
        ),
      ActivityFamily.lodging => const DashboardSnapshot(
          revenueToday: 145000,
          activityCount: 9,
          activityLabel: 'chambres occupées',
          rating: 4.4,
          reviewsCount: 87,
          week: [120000, 165000, 210000, 190000, 98000, 110000, 145000],
          weekLabels: labels,
          inbox: [
            InboxItem(title: '2 réservations à confirmer', subtitle: 'Le client attend votre réponse', target: InboxTarget.activity, urgent: true),
            InboxItem(title: '3 arrivées aujourd’hui', subtitle: 'Check-in avec le code du client', target: InboxTarget.activity),
          ],
        ),
      ActivityFamily.rental => const DashboardSnapshot(
          revenueToday: 0,
          activityCount: 4,
          activityLabel: 'demandes de visite',
          rating: 4.8,
          reviewsCount: 15,
          week: [0, 0, 150000, 0, 0, 0, 0],
          weekLabels: labels,
          inbox: [
            InboxItem(title: '2 demandes de visite', subtitle: 'Acceptez ou proposez un autre créneau', target: InboxTarget.activity, urgent: true),
            InboxItem(title: 'Versement du 1er du mois', subtitle: 'Loyer de l’appartement B2 reçu', target: InboxTarget.finances),
          ],
        ),
      ActivityFamily.transport => const DashboardSnapshot(
          revenueToday: 412000,
          activityCount: 64,
          activityLabel: 'billets vendus',
          rating: 4.2,
          reviewsCount: 341,
          week: [380000, 455000, 520000, 498000, 301000, 356000, 412000],
          weekLabels: labels,
          inbox: [
            InboxItem(title: 'Départ de 14 h 00 vers Parakou', subtitle: 'Embarquement dans 40 min · 6 places libres', target: InboxTarget.activity, urgent: true),
            InboxItem(title: '2 avis sans réponse', subtitle: 'Dont 1 sur la climatisation', target: InboxTarget.reviews),
          ],
        ),
    };
  }
}
