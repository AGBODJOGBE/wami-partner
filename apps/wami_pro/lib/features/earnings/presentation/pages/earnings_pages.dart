import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/pro_accent.dart';
import '../../../../shared/routes.dart';
import '../../domain/entities/earnings.dart';
import '../cubit/earnings_cubits.dart';

// ─── Onglet Gains ────────────────────────────────────────────────────────────

class EarningsPage extends StatelessWidget {
  const EarningsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return BlocBuilder<EarningsCubit, (EarningsPeriod, DataState<EarningsSummary>)>(
      builder: (context, st) {
        final (period, s) = st;
        final cubit = context.read<EarningsCubit>();
        final e = s.data;
        return WamiBackground(
          glow: ProAccent.glow,
          child: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: cubit.load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(WamiSpace.screen, 12, WamiSpace.screen, 110),
                children: [
                  Row(children: [
                    Expanded(child: Text('Gains', style: t.headlineSmall)),
                    WamiIconButton(icon: Icons.account_balance_wallet_outlined, tooltip: 'Portefeuille', onPressed: () => context.push(ProRoutes.wallet)),
                    const SizedBox(width: 8),
                    WamiIconButton(icon: Icons.emoji_events_outlined, tooltip: 'Performances', onPressed: () => context.push(ProRoutes.performance)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    for (final p in EarningsPeriod.values) ...[
                      WamiChip(label: p.label, selected: p == period, onTap: () => cubit.load(p)),
                      const SizedBox(width: 8),
                    ],
                  ]),
                  const SizedBox(height: 16),
                  if (s.status == LoadStatus.failure)
                    WamiErrorView(failure: s.failure!, onRetry: cubit.load)
                  else if (e == null)
                    const SizedBox(height: 300, child: WamiLoading())
                  else ...[
                    Text(e.rangeLabel, style: t.bodySmall),
                    NumberText(Fmt.fcfa(e.total), size: 32),
                    Text(
                      '${e.trendPercent >= 0 ? '+' : ''}${e.trendPercent} % par rapport à la période précédente',
                      style: t.bodySmall?.copyWith(color: e.trendPercent >= 0 ? WamiColors.success : context.wami.danger),
                    ),
                    const SizedBox(height: 14),
                    GlassCard(child: MiniBarChart(values: e.bars, labels: e.barLabels, highlight: e.bestIndex)),
                    const SizedBox(height: 14),
                    GlassGroup(children: [
                      for (final l in e.lines)
                        InfoRow(l.label, Fmt.fcfa(l.amount), valueColor: l.amount < 0 ? context.wami.danger : null),
                    ]),
                    const SizedBox(height: 8),
                    Text('Montants d’exemple tant que l’API n’est pas branchée.', style: t.bodySmall?.copyWith(fontSize: 11)),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Portefeuille partenaire ─────────────────────────────────────────────────

class PartnerWalletPage extends StatelessWidget {
  const PartnerWalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return BlocConsumer<PartnerWalletCubit, DataState<PartnerWallet>>(
      listenWhen: (a, b) => (b.failure != null && a.failure != b.failure) || (!a.done && b.done),
      listener: (context, s) {
        if (s.failure != null) showWamiMessage(context, s.failure!.message);
        if (s.done) showWamiMessage(context, 'Retrait demandé. Arrivée sous [délai à valider].');
      },
      builder: (context, s) {
        final w = s.data;
        return WamiScreen(
          title: 'Portefeuille',
          glow: ProAccent.glow,
          body: w == null
              ? const SizedBox(height: 300, child: WamiLoading())
              : Gap(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(WamiRadius.xl),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                        gradient: const LinearGradient(colors: [Color(0xFF1E2F57), Color(0xFF0E1830)]),
                        boxShadow: [BoxShadow(color: ProAccent.glow.withValues(alpha: 0.25), blurRadius: 40)],
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const SectionLabel('Disponible au retrait'),
                        NumberText(Fmt.fcfa(w.withdrawable), size: 32, color: Colors.white),
                        const SizedBox(height: 4),
                        Text(w.payoutSchedule, style: t.bodySmall),
                      ]),
                    ),
                    if (w.cashCommissionDue > 0)
                      GlassCard(
                        borderColor: WamiColors.glowHebergement.withValues(alpha: 0.4),
                        child: Row(children: [
                          const WamiTag('Espèces', tint: WamiColors.glowHebergement),
                          const SizedBox(width: 10),
                          const Expanded(child: Text('Commission due sur courses en espèces')),
                          Text('− ${Fmt.fcfa(w.cashCommissionDue)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    const SectionLabel('Retirer vers'),
                    GlassCard(child: ListRow(title: w.payoutMethod, icon: Icons.phone_android_rounded, trailing: const WamiTag('Par défaut', tint: WamiColors.success))),
                    const SectionLabel('Derniers mouvements'),
                    GlassGroup(children: [
                      for (final m in w.movements)
                        InfoRow(
                          '${m.label} · ${Fmt.relativeDay(m.date)}',
                          Fmt.fcfa(m.amount, signed: true),
                          valueColor: m.amount > 0 ? WamiColors.success : null,
                        ),
                    ]),
                  ],
                ),
          bottom: WamiPrimaryButton(
            label: w == null ? 'Retirer' : 'Retirer ${Fmt.fcfa(w.withdrawable)}',
            icon: Icons.upload_rounded,
            loading: s.busy,
            onPressed: w == null || w.withdrawable == 0 ? null : context.read<PartnerWalletCubit>().withdrawAll,
          ),
        );
      },
    );
  }
}

// ─── Performances ────────────────────────────────────────────────────────────

class PerformancePage extends StatelessWidget {
  const PerformancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return BlocBuilder<PerformanceCubit, DataState<Performance>>(
      builder: (context, s) {
        final p = s.data;
        return WamiScreen(
          title: 'Performances',
          glow: ProAccent.glow,
          body: p == null
              ? const SizedBox(height: 300, child: WamiLoading())
              : Gap(
                  children: [
                    KpiRow(children: [
                      KpiTile(value: p.rating.toStringAsFixed(1).replaceAll('.', ','), label: 'note moyenne', color: WamiColors.star),
                      KpiTile(value: '${(p.acceptanceRate * 100).round()} %', label: 'acceptées'),
                      KpiTile(value: '${(p.cancellationRate * 100).round()} %', label: 'annulées'),
                    ]),
                    ActionCard(
                      hot: true,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Row(children: [
                          const Icon(Icons.card_giftcard_rounded, color: WamiColors.orangeLight),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Objectif de la semaine', style: t.titleSmall)),
                          WamiTag('+ ${Fmt.fcfa(p.goalBonus)}'),
                        ]),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(value: p.goalProgress, minHeight: 8, color: WamiColors.orangeLight, backgroundColor: Colors.white12),
                        ),
                        const SizedBox(height: 6),
                        Text('${p.goalDone} missions sur ${p.goalTarget}', style: t.bodySmall),
                      ]),
                    ),
                    GlassCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Niveau ${p.level}', style: t.titleSmall),
                        Text(p.nextLevelHint, style: t.bodySmall),
                      ]),
                    ),
                    const SectionLabel('Ce que disent les clients'),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final e in p.tags.entries) WamiChip(label: '${e.key} · ${e.value}', selected: false, onTap: null),
                    ]),
                    if (p.lastReview != null) GlassCard(child: Text('« ${p.lastReview} »')),
                  ],
                ),
        );
      },
    );
  }
}
