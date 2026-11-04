import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/pro_accent.dart';
import '../../domain/entities/history.dart';
import '../cubit/history_cubit.dart';

Color _tint(HistoryOutcome o) => switch (o) {
      HistoryOutcome.done => WamiColors.success,
      HistoryOutcome.cancelled => WamiColors.danger,
      HistoryOutcome.failed => WamiColors.glowHebergement,
      HistoryOutcome.inProgress => WamiColors.white,
    };

/// Historique des courses et des livraisons, avec filtre sur le résultat.
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return BlocConsumer<HistoryCubit, HistoryState>(
      listenWhen: (a, b) => b.failure != null && a.failure != b.failure,
      listener: (context, s) => showWamiMessage(context, s.failure!.message),
      builder: (context, s) {
        final cubit = context.read<HistoryCubit>();
        final rides = s.tab == HistoryTab.rides;
        final empty = rides ? s.shownRides.isEmpty : s.shownDeliveries.isEmpty;
        return WamiScreen(
          title: 'Historique',
          glow: ProAccent.glow,
          body: Gap(
            children: [
              WamiSegmented<HistoryTab>(
                options: const [(HistoryTab.rides, 'Courses'), (HistoryTab.deliveries, 'Livraisons')],
                value: s.tab,
                onChanged: cubit.setTab,
              ),
              Wrap(spacing: 8, runSpacing: 8, children: [
                WamiChip(label: 'Tout', selected: s.filter == null, onTap: () => cubit.setFilter(null)),
                for (final o in [HistoryOutcome.done, HistoryOutcome.cancelled, HistoryOutcome.failed])
                  WamiChip(label: o.label, selected: s.filter == o, onTap: () => cubit.setFilter(o)),
              ]),
              if (s.status.isLoading && s.rides.isEmpty && s.deliveries.isEmpty)
                const SizedBox(height: 200, child: WamiLoading())
              else if (empty)
                Text('Rien à afficher pour ce filtre.', style: t.bodySmall)
              else if (rides)
                GlassGroup(children: [
                  for (final r in s.shownRides)
                    ListRow(
                      title: '${r.pickup} → ${r.dropoff}',
                      subtitle: '${Fmt.relativeDay(r.date)} · ${r.statusLabel}${r.passenger.isEmpty ? '' : ' · ${r.passenger}'}',
                      icon: Icons.local_taxi_rounded,
                      iconColor: _tint(r.outcome),
                      trailing: NumberText(Fmt.fcfa(r.earnings ?? 0), size: 14),
                    ),
                ])
              else
                GlassGroup(children: [
                  for (final d in s.shownDeliveries)
                    ListRow(
                      title: '${d.pickup} → ${d.dropoff}',
                      subtitle: '${Fmt.relativeDay(d.date)} · ${d.statusLabel}${d.cancelReason == null ? '' : ' · ${d.cancelReason}'}',
                      icon: Icons.inventory_2_outlined,
                      iconColor: _tint(d.outcome),
                      trailing: NumberText(Fmt.fcfa(d.price), size: 14),
                    ),
                ]),
            ],
          ),
        );
      },
    );
  }
}
