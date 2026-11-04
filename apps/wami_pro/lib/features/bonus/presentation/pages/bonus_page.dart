import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/data_state.dart';
import '../../../../shared/pro_accent.dart';
import '../../domain/entities/bonus.dart';
import '../cubit/bonus_cubit.dart';

String _pct(double v) => '${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1).replaceAll('.', ',')} %';

/// Bonus du partenaire : activité du jour, jalons, qualité du mois, et transfert vers le solde retirable.
class BonusPage extends StatelessWidget {
  const BonusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return BlocConsumer<BonusCubit, DataState<BonusOverview>>(
      listenWhen: (a, b) => (b.failure != null && a.failure != b.failure) || (!a.done && b.done),
      listener: (context, s) {
        if (s.failure != null) showWamiMessage(context, s.failure!.message);
        if (s.done) showWamiMessage(context, 'Bonus transféré vers votre solde.');
      },
      builder: (context, s) {
        final b = s.data;
        return WamiScreen(
          title: 'Bonus',
          glow: ProAccent.glow,
          body: b == null
              ? const SizedBox(height: 300, child: WamiLoading())
              : Gap(
                  children: [
                    GlassCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const SectionLabel('Solde de bonus'),
                        NumberText(Fmt.fcfa(b.bonusBalance), size: 28),
                        if (b.referralBalance > 0) Text('Parrainage : ${Fmt.fcfa(b.referralBalance)}', style: t.bodySmall),
                        const SizedBox(height: 4),
                        Text('Les bonus ne se retirent pas tels quels : transférez-les vers votre solde principal (des frais s’appliquent).',
                            style: t.bodySmall?.copyWith(fontSize: 11.5)),
                      ]),
                    ),
                    if (b.activity != null) _activity(context, b.activity!),
                    if (b.quality != null) _quality(context, b.quality!),
                    if (b.milestone != null) _milestone(context, b.milestone!),
                    if (b.activity == null && b.quality == null && b.milestone == null)
                      Text('Aucun bonus n’est actif pour le moment.', style: t.bodySmall),
                  ],
                ),
          bottom: WamiPrimaryButton(
            label: b == null ? 'Transférer' : 'Transférer ${Fmt.fcfa(b.bonusBalance)}',
            icon: Icons.swap_horiz_rounded,
            loading: s.busy,
            onPressed: b == null || b.bonusBalance < 500 ? null : context.read<BonusCubit>().consolidateAll,
          ),
        );
      },
    );
  }

  Widget _activity(BuildContext context, ActivityBonus a) {
    final t = Theme.of(context).textTheme;
    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Activité du jour', style: t.titleSmall)),
          WamiTag(a.currentTier ?? 'Aucun palier'),
        ]),
        const SizedBox(height: 8),
        InfoRow('Missions aujourd’hui', '${a.ridesToday}'),
        InfoRow('Pourcentage actuel', _pct(a.currentPercent)),
        InfoRow(a.provisional ? 'Bonus estimé (provisoire)' : 'Bonus du jour', Fmt.fcfa(a.estimatedToday), strong: true),
        if (a.nextTier != null) Text('Palier « ${a.nextTier} » dans ${a.ridesRemaining} mission(s).', style: t.bodySmall),
      ]),
    );
  }

  Widget _quality(BuildContext context, QualityBonus q) {
    final t = Theme.of(context).textTheme;
    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Qualité du mois', style: t.titleSmall),
        const SizedBox(height: 8),
        InfoRow('Note moyenne', q.averageRating.toStringAsFixed(2).replaceAll('.', ',')),
        InfoRow('Missions du mois', '${q.ridesThisMonth} / ${q.minRides} minimum'),
        if (q.current != null)
          InfoRow('Palier atteint', q.current!.name, valueColor: WamiColors.success)
        else if (q.ridesRemaining > 0)
          Text('Encore ${q.ridesRemaining} mission(s) pour être éligible.', style: t.bodySmall),
        if (q.next != null) Text('Prochain palier : ${q.next!.name}.', style: t.bodySmall),
      ]),
    );
  }

  Widget _milestone(BuildContext context, MilestoneBonus m) {
    final t = Theme.of(context).textTheme;
    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Jalons', style: t.titleSmall),
        const SizedBox(height: 8),
        InfoRow('Missions au total', '${m.totalRides}'),
        for (final u in m.unlocked) InfoRow(u.name, u.amount == null ? 'Atteint' : '+ ${Fmt.fcfa(u.amount!)}', valueColor: WamiColors.success),
        if (m.next != null) Text('Prochain jalon : ${m.next!.name}, dans ${m.ridesRemaining} mission(s).', style: t.bodySmall),
      ]),
    );
  }
}
