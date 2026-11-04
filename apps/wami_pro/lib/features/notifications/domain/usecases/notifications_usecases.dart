import 'package:wami_core/wami_core.dart';

import '../entities/app_notification.dart';
import '../repositories/notifications_repository.dart';

class GetNotifications implements UseCase<List<AppNotification>, NoParams> {
  const GetNotifications(this._repo);
  final NotificationsRepository _repo;

  @override
  Future<Result<List<AppNotification>>> call(NoParams _) => _repo.getNotifications();
}

class MarkNotificationRead implements UseCase<void, String> {
  const MarkNotificationRead(this._repo);
  final NotificationsRepository _repo;

  @override
  Future<Result<void>> call(String id) => _repo.markRead(id);
}
