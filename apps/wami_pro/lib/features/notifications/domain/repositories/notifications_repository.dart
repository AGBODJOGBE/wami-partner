import 'package:wami_core/wami_core.dart';

import '../entities/app_notification.dart';

abstract interface class NotificationsRepository {
  Future<Result<List<AppNotification>>> getNotifications();
  Future<Result<void>> markRead(String id);
}
