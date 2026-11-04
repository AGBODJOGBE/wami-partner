import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/biz_accent.dart';
import '../../../../shared/data_state.dart';
import '../../domain/entities/establishment.dart';
import '../cubit/establishment_cubit.dart';

/// Onglet « Tableau » : établissement courant, ouverture, chiffres du jour, à traiter.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.establishmentId, required this.onOpen});
  final String establishmentId;

  /// Fourni par le routeur : ouvre l'onglet ou la page visée par un élément « à traiter ».
  final ValueChanged<InboxTarget> onOpen;

  @override
  Widget build(BuildContext context) {
    final est = context.watch<EstablishmentCubit>().state;
    final e = est.current;
    final t = Theme.of(context).textTheme;
    if (e == null) return const Scaffold(body: WamiLoading());

    return BlocListener<EstablishmentCubit, EstablishmentState>(
      listenWhen: (a, b) => b.failure != null && a.failure != b.failure,
      listener: (context, s) => showWamiMessage(context, s.failure!.message),
      child: WamiScreen(
        showBack: false,
        glow: BizAccent.glow,
        title: null,
        body: BlocBuilder<DashboardCubit, DataState<DashboardSnapshot>>(
          builder: (context, s) {
            final d = s.data;
            return Gap(
              children: [
                _EstablishmentSwitcher(current: e, items: est.items),
                GlassCard(
                  child: ToggleRow(
                    title: e.open ? 'Ouvert aux clients' : 'Fermé aux nouvelles demandes',
                    subtitle: e.open ? 'Vous recevez commandes et réservations' : 'Les demandes acceptées restent à honorer',
                    value: e.open,
                    onChanged: context.read<EstablishmentCubit>().setOpen,
                  ),
                ),
                if (d == null && s.status == LoadStatus.failure)
                  WamiErrorView(failure: s.failure!, onRetry: () => context.read<DashboardCubit>().load(establishmentId))
                else if (d == null)
                  const SizedBox(height: 160, child: WamiLoading())
                else ...[
                  KpiRow(children: [
                    KpiTile(value: Fmt.fcfa(d.revenueToday, withUnit: false), label: 'FCFA aujourd’hui', color: BizAccent.soft),
                    KpiTile(value: '${d.activityCount}', label: d.activityLabel),
                    KpiTile(value: d.rating.toStringAsFixed(1), label: '${d.reviewsCount} avis', color: WamiColors.star),
                  ]),
                  SectionLabel('À traiter', trailing: d.urgentCount > 0 ? WamiTag('${d.urgentCount} urgent', tint: WamiColors.orangeLight) : null),
                  if (d.inbox.isEmpty)
                    const EmptyState(icon: Icons.inbox_rounded, message: 'Rien en attente. Tout est à jour.')
                  else
                    for (final i in d.inbox)
                      ActionCard(
                        hot: i.urgent,
                        onTap: () => onOpen(i.target),
                        child: Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(i.title, style: t.titleSmall),
                              const SizedBox(height: 2),
                              Text(i.subtitle, style: t.bodySmall),
                            ]),
                          ),
                          Icon(Icons.chevron_right_rounded, color: context.wami.inkMuted),
                        ]),
                      ),
                  const SectionLabel('7 derniers jours'),
                  GlassCard(
                    child: MiniBarChart(values: d.week, labels: d.weekLabels, highlight: d.week.length - 1, color: BizAccent.glow),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EstablishmentSwitcher extends StatelessWidget {
  const _EstablishmentSwitcher({required this.current, required this.items});
  final Establishment current;
  final List<Establishment> items;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final canSwitch = items.length > 1;
    return GlassCard(
      onTap: canSwitch ? () => _pick(context) : null,
      child: Row(children: [
        current.activity.art != null
            ? ServiceIllustration(current.activity.art!, size: 44)
            : IconBadge(current.activity.icon, color: BizAccent.glow, size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(current.name, style: t.titleMedium, overflow: TextOverflow.ellipsis),
            Text('${current.activity.label} · ${current.district}', style: t.bodySmall, overflow: TextOverflow.ellipsis),
          ]),
        ),
        if (canSwitch) Icon(Icons.unfold_more_rounded, color: context.wami.inkMuted),
      ]),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final cubit = context.read<EstablishmentCubit>();
    final id = await showBizSheet<String>(context, children: (sheet) => [
          const SectionLabel('Mes établissements'),
          for (final e in items)
            WamiOptionTile(
              title: e.name,
              subtitle: e.activity.label,
              selected: e.id == current.id,
              onTap: () => Navigator.pop(sheet, e.id),
            ),
        ]);
    if (id != null) cubit.select(id);
  }
}
