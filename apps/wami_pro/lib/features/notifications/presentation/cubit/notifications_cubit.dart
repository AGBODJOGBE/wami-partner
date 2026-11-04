import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/data_state.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/usecases/notifications_usecases.dart';

class NotificationsCubit extends Cubit<DataState<List<AppNotification>>> {
  NotificationsCubit(this._get, this._markRead) : super(const DataState());
  final GetNotifications _get;
  final MarkNotificationRead _markRead;

  Future<void> load() async {
    emit(const DataState(status: LoadStatus.loading));
    final r = await _get(const NoParams());
    emit(r.fold(
      (f) => DataState(status: LoadStatus.failure, failure: f),
      (d) => DataState(status: LoadStatus.ready, data: d),
    ));
  }

  /// Marque comme lue : on met à jour l'écran tout de suite, le serveur suit.
  Future<void> read(AppNotification n) async {
    final list = state.data;
    if (list == null || n.read) return;
    emit(DataState(status: LoadStatus.ready, data: [for (final x in list) x.id == n.id ? x.markRead() : x]));
    await _markRead(n.id);
  }
}
