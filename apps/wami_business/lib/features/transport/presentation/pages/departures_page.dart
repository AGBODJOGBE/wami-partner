import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/biz_accent.dart';
import '../../../../shared/data_state.dart';
import '../../../../shared/routes.dart';
import '../../domain/entities/transport.dart';
import '../cubit/transport_cubits.dart';

/// Onglet « Activité » d'une compagnie de bus : départs du jour.
class DeparturesPage extends StatelessWidget {
  const DeparturesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DeparturesCubit>();
    return BlocConsumer<DeparturesCubit, DataState<List<Departure>>>(
      listenWhen: (a, b) => b.failure != null && a.failure != b.failure,
      listener: (context, s) => showWamiMessage(context, s.failure!.message),
      builder: (context, s) {
        final list = s.data;
        return WamiScreen(
          showBack: false,
          title: 'Départs',
          subtitle: 'Aujourd’hui',
          glow: BizAccent.glow,
          actions: [WamiIconButton(icon: Icons.refresh_rounded, tooltip: 'Actualiser', onPressed: cubit.reload)],
          body: list == null
              ? (s.status == LoadStatus.failure
                  ? WamiErrorView(failure: s.failure!, onRetry: cubit.reload)
                  : const SizedBox(height: 300, child: WamiLoading()))
              : list.isEmpty
                  ? const EmptyState(icon: Icons.directions_bus_rounded, message: 'Aucun départ programmé aujourd’hui.')
                  : Gap(children: [for (final d in list) _DepartureCard(departure: d, busy: s.busy)]),
        );
      },
    );
  }
}

class _DepartureCard extends StatelessWidget {
  const _DepartureCard({required this.departure, required this.busy});
  final Departure departure;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cubit = context.read<DeparturesCubit>();
    final d = departure;
    final now = DateTime.now();
    final total = d.seats.length;
    return ActionCard(
      hot: d.boardingOpen(now),
      child: Gap(gap: 10, children: [
        Row(children: [
          NumberText(Fmt.hhmm(d.effectiveAt), size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(d.line.label, style: t.titleSmall, overflow: TextOverflow.ellipsis)),
          if (d.departed)
            const WamiTag('Parti')
          else if (d.delayMinutes > 0)
            WamiTag('+${d.delayMinutes} min', tint: WamiColors.orangeLight)
          else if (d.boardingOpen(now))
            const WamiTag('Embarquement', tint: BizAccent.glow),
        ]),
        // Remplissage par canal : app (turquoise), guichet (orange).
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: Row(children: [
              if (d.soldApp + d.boarded > 0) Expanded(flex: d.soldApp + d.boarded, child: Container(color: BizAccent.glow)),
              if (d.soldCounter > 0) Expanded(flex: d.soldCounter, child: Container(color: WamiColors.orangeLight)),
              if (total - d.sold > 0) Expanded(flex: total - d.sold, child: Container(color: context.wami.glass)),
            ]),
          ),
        ),
        Text(
          '${d.sold}/$total vendus · ${d.soldApp + d.boarded} app, ${d.soldCounter} guichet · ${d.free} libres',
          style: t.bodySmall,
        ),
        if (!d.departed)
          Row(children: [
            Expanded(
              child: WamiGhostButton(
                label: 'Places',
                icon: Icons.event_seat_rounded,
                onPressed: () async {
                  await context.push(BizRoutes.seats, extra: d.id);
                  cubit.reload();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: WamiGhostButton(
                label: 'Retard',
                icon: Icons.schedule_rounded,
                onPressed: busy ? null : () => _delay(context, cubit),
              ),
            ),
          ]),
        if (d.boardingOpen(now))
          WamiPrimaryButton(
            label: 'Embarquement (${d.boarded}/${d.sold})',
            icon: Icons.qr_code_scanner_rounded,
            height: 50,
            onPressed: () async {
              await context.push(BizRoutes.boarding, extra: d.id);
              cubit.reload();
            },
          ),
      ]),
    );
  }

  Future<void> _delay(BuildContext context, DeparturesCubit cubit) async {
    final minutes = await showBizSheet<int>(context, children: (sheet) => [
          Text('Signaler un retard', style: Theme.of(sheet).textTheme.titleMedium),
          Text('Les voyageurs sont prévenus dans l’app.', style: Theme.of(sheet).textTheme.bodySmall),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final m in DelayRules.presets) WamiChip(label: '+$m min', selected: false, onTap: () => Navigator.pop(sheet, m)),
          ]),
        ]);
    if (minutes != null) await cubit.reportDelay(departure, minutes);
  }
}
