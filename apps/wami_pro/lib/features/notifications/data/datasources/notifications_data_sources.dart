import 'package:wami_core/wami_core.dart';

import '../../domain/entities/app_notification.dart';

abstract interface class NotificationsRemoteDataSource {
  Future<List<AppNotification>> list();
  Future<void> markRead(String id);
}

/// `/api/notifications`. On n'envoie jamais `recipientId` : le serveur prend l'utilisateur du jeton
/// (la route accepterait l'identifiant d'un autre, ce qu'il ne faut pas exploiter).
class NotificationsApiDataSource implements NotificationsRemoteDataSource {
  const NotificationsApiDataSource(this._api);
  final ApiClient _api;

  @override
  Future<List<AppNotification>> list() async {
    final j = await _api.get('/api/notifications', query: {'page': 1, 'limit': 50});
    return ((j['notifications'] as List<dynamic>?) ?? const []).cast<Map<String, dynamic>>().map((n) {
      return AppNotification(
        id: n['id'] as String,
        message: (n['message'] as String?) ?? '',
        type: (n['type'] as String?) ?? '',
        read: n['isRead'] == true,
        createdAt: DateTime.tryParse('${n['createdAt']}')?.toLocal() ?? DateTime.now(),
      );
    }).toList();
  }

  @override
  Future<void> markRead(String id) => _api.patch('/api/notifications/$id/read');
}

class NotificationsFakeDataSource implements NotificationsRemoteDataSource {
  NotificationsFakeDataSource(this._fake);
  final FakeBackend _fake;

  late final _items = <AppNotification>[
    AppNotification(id: 'n1', message: 'Votre assurance expire dans 12 jours.', createdAt: DateTime.now().subtract(const Duration(hours: 3)), read: false),
    AppNotification(id: 'n2', message: 'Bonus d’activité crédité : 370 FCFA.', createdAt: DateTime.now().subtract(const Duration(days: 1)), read: true),
  ];

  @override
  Future<List<AppNotification>> list() async {
    await _fake.latency(0.4);
    return List.unmodifiable(_items);
  }

  @override
  Future<void> markRead(String id) async {
    final i = _items.indexWhere((n) => n.id == id);
    if (i >= 0) _items[i] = _items[i].markRead();
  }
}
