import 'package:wami_core/wami_core.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_data_sources.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl(this._remote);
  final NotificationsRemoteDataSource _remote;

  @override
  Future<Result<List<AppNotification>>> getNotifications() => guard(_remote.list);

  @override
  Future<Result<void>> markRead(String id) => guard(() => _remote.markRead(id));
}
