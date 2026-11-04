import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/biz_accent.dart';
import '../../../../shared/data_state.dart';
import '../../../../shared/routes.dart';
import '../../domain/entities/finances.dart';
import '../cubit/finances_cubit.dart';

/// Onglet « Finances » : prochain versement, évolution, historique.
class FinancesPage extends StatelessWidget {
  const FinancesPage({super.key, required this.establishmentId});
  final String establishmentId;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return BlocBuilder<FinancesCubit, DataState<FinanceOverview>>(
      builder: (context, s) {
        final f = s.data;
        return WamiScreen(
          showBack: false,
          title: 'Finances',
          glow: BizAccent.glow,
          body: f == null
              ? (s.status == LoadStatus.failure
                  ? WamiErrorView(failure: s.failure!, onRetry: () => context.read<FinancesCubit>().load(establishmentId))
                  : const SizedBox(height: 300, child: WamiLoading()))
              : Gap(children: [
                  GlassCard(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [BizAccent.glow.withValues(alpha: 0.22), context.wami.glass],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Prochain versement', style: t.bodySmall),
                      const SizedBox(height: 4),
                      NumberText(Fmt.fcfa(f.pending), size: 30, glow: true),
                      const SizedBox(height: 6),
                      Text('${Fmt.dayMonth(f.nextPayoutDate)} · ${f.payoutMethod}', style: t.bodySmall),
                      Text('Commission WAMI : ${(f.commissionRate * 100).round()} % (à valider)', style: t.bodySmall),
                    ]),
                  ),
                  const SectionLabel('Ventes par mois'),
                  GlassCard(child: MiniBarChart(values: f.months, labels: f.monthLabels, highlight: f.months.length - 1, color: BizAccent.glow)),
                  const SectionLabel('Versements'),
                  GlassGroup(children: [
                    for (final p in f.payouts)
                      ListRow(
                        title: '${p.period} · ${Fmt.fcfa(p.net)}',
                        subtitle: '${p.status.label} le ${Fmt.dayMonth(p.date)}',
                        icon: p.status == PayoutStatus.failed ? Icons.error_outline_rounded : Icons.payments_rounded,
                        iconColor: p.status == PayoutStatus.failed ? WamiColors.danger : BizAccent.glow,
                        trailing: Icon(Icons.chevron_right_rounded, color: context.wami.inkMuted),
                        onTap: () => context.push(BizRoutes.payout, extra: p),
                      ),
                  ]),
                ]),
        );
      },
    );
  }
}

/// Détail d'un versement : ventes, commission, ajustements, net.
class PayoutDetailPage extends StatelessWidget {
  const PayoutDetailPage({super.key, required this.payout});
  final Payout payout;

  @override
  Widget build(BuildContext context) {
    final p = payout;
    return WamiScreen(
      title: p.period,
      subtitle: '${p.status.label} le ${Fmt.dayMonth(p.date)}',
      glow: BizAccent.glow,
      body: Gap(children: [
        GlassCard(
          child: Column(children: [
            InfoRow('Ventes', Fmt.fcfa(p.gross)),
            InfoRow('Commission WAMI', Fmt.fcfa(-p.commission, signed: true), valueColor: context.wami.inkMuted),
            for (final a in p.adjustments)
              InfoRow(a.label, Fmt.fcfa(a.amount, signed: true), valueColor: a.amount < 0 ? WamiColors.danger : WamiColors.success),
            const Divider(height: 22),
            InfoRow('Net versé', Fmt.fcfa(p.net), strong: true),
          ]),
        ),
        InfoRow('Moyen', p.method),
        Text('Relevé PDF : à valider.', style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}
