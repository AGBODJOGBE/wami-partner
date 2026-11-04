import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/data_state.dart';
import '../../../../shared/pro_accent.dart';
import '../../domain/entities/app_notification.dart';
import '../cubit/notifications_cubit.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return BlocBuilder<NotificationsCubit, DataState<List<AppNotification>>>(
      builder: (context, s) {
        final items = s.data;
        return WamiScreen(
          title: 'Notifications',
          glow: ProAccent.glow,
          body: switch (s.status) {
            LoadStatus.idle || LoadStatus.loading => const SizedBox(height: 300, child: WamiLoading()),
            LoadStatus.failure => Text(s.failure?.message ?? 'Notifications indisponibles.', style: t.bodySmall),
            _ when items == null || items.isEmpty => Text('Aucune notification pour le moment.', style: t.bodySmall),
            _ => GlassGroup(children: [
                for (final n in items)
                  ListRow(
                    title: n.message,
                    subtitle: Fmt.relativeDay(n.createdAt),
                    icon: n.read ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
                    iconColor: n.read ? null : WamiColors.orangeLight,
                    onTap: () => context.read<NotificationsCubit>().read(n),
                  ),
              ]),
          },
        );
      },
    );
  }
}
