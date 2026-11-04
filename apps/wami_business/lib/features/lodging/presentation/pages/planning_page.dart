import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/biz_accent.dart';
import '../../../../shared/data_state.dart';
import '../../../../shared/routes.dart';
import '../../domain/entities/lodging.dart';
import '../cubit/lodging_cubits.dart';

/// Onglet « Activité » d'un hôtel ou de chambres : planning, demandes, arrivées.
class PlanningPage extends StatelessWidget {
  const PlanningPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlanningCubit>();
    final t = Theme.of(context).textTheme;
    return BlocConsumer<PlanningCubit, DataState<Planning>>(
      listenWhen: (a, b) => b.failure != null && a.failure != b.failure,
      listener: (context, s) => showWamiMessage(context, s.failure!.message),
      builder: (context, s) {
        final p = s.data;
        final today = dateOnly(DateTime.now());
        return WamiScreen(
          showBack: false,
          title: 'Planning',
          glow: BizAccent.glow,
          actions: [
            WamiIconButton(
              icon: Icons.qr_code_scanner_rounded,
              tooltip: 'Check-in',
              onPressed: () async {
                if (await context.push<bool>(BizRoutes.checkIn) == true) cubit.reload();
              },
            ),
          ],
          body: p == null
              ? (s.status == LoadStatus.failure
                  ? WamiErrorView(failure: s.failure!, onRetry: cubit.reload)
                  : const SizedBox(height: 300, child: WamiLoading()))
              : Gap(
                  children: [
                    Row(children: [
                      WamiIconButton(icon: Icons.chevron_left_rounded, tooltip: 'Semaine précédente', onPressed: () => cubit.shiftWeek(-1)),
                      Expanded(
                        child: Text(
                          'Du ${Fmt.dayMonth(p.dates.first)} au ${Fmt.dayMonth(p.dates.last)}',
                          textAlign: TextAlign.center,
                          style: t.titleSmall,
                        ),
                      ),
                      WamiIconButton(icon: Icons.chevron_right_rounded, tooltip: 'Semaine suivante', onPressed: () => cubit.shiftWeek(1)),
                    ]),
                    GlassCard(padding: const EdgeInsets.all(10), child: _OccupancyGrid(planning: p)),
                    Text('Chiffre = chambres encore libres à la vente.', style: t.bodySmall),
                    SectionLabel('À confirmer', trailing: p.pending.isEmpty ? null : WamiTag('${p.pending.length}', tint: WamiColors.orangeLight)),
                    if (p.pending.isEmpty)
                      const EmptyState(icon: Icons.event_available_rounded, message: 'Aucune demande en attente.')
                    else
                      for (final b in p.pending) _PendingCard(booking: b, type: p.typeOf(b), busy: s.busy),
                    SectionLabel('Arrivées aujourd’hui (${p.arrivals(today).length})'),
                    if (p.arrivals(today).isEmpty)
                      Text('Aucune arrivée confirmée aujourd’hui.', style: t.bodySmall)
                    else
                      GlassGroup(children: [
                        for (final b in p.arrivals(today))
                          ListRow(
                            title: b.guestName,
                            subtitle: '${p.typeOf(b)?.name ?? ''} · ${b.nights} nuit${b.nights > 1 ? 's' : ''}',
                            icon: Icons.luggage_rounded,
                            trailing: Text(b.channel == BookingChannel.desk ? 'Comptoir' : 'App', style: t.bodySmall),
                          ),
                      ]),
                  ],
                ),
          bottom: WamiPrimaryButton(
            label: 'Réservation au comptoir',
            icon: Icons.add_rounded,
            onPressed: () async {
              if (await context.push<bool>(BizRoutes.deskBooking) == true) cubit.reload();
            },
          ),
        );
      },
    );
  }
}

class _OccupancyGrid extends StatelessWidget {
  const _OccupancyGrid({required this.planning});
  final Planning planning;

  static const _initials = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final p = context.wami;
    final small = Theme.of(context).textTheme.bodySmall;
    Widget cell(Widget child, {Color? color}) => Expanded(
          child: Container(
            height: 34,
            margin: const EdgeInsets.all(2),
            alignment: Alignment.center,
            decoration: color == null ? null : BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
            child: child,
          ),
        );

    return Column(children: [
      Row(children: [
        const SizedBox(width: 92),
        for (final d in planning.dates) cell(Text('${_initials[d.weekday - 1]}\n${d.day}', textAlign: TextAlign.center, style: small)),
      ]),
      for (final type in planning.roomTypes)
        Row(children: [
          SizedBox(
            width: 92,
            child: Text(type.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: small?.copyWith(color: p.ink)),
          ),
          for (final d in planning.dates)
            Builder(builder: (context) {
              final free = planning.free(type, d);
              final color = free == 0
                  ? WamiColors.danger.withValues(alpha: 0.28)
                  : (free == 1 ? WamiColors.orangeLight.withValues(alpha: 0.22) : BizAccent.glow.withValues(alpha: 0.16));
              return cell(Text('$free', style: WamiTypography.number(14, color: p.ink)), color: color);
            }),
        ]),
    ]);
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({required this.booking, required this.type, required this.busy});
  final Booking booking;
  final RoomType? type;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cubit = context.read<PlanningCubit>();
    final b = booking;
    return ActionCard(
      hot: true,
      child: Gap(gap: 10, children: [
        Row(children: [
          Expanded(child: Text(b.guestName, style: t.titleMedium)),
          NumberText(Fmt.fcfa(b.amount), size: 14),
        ]),
        Text(
          '${type?.name ?? 'Chambre'} · ${Fmt.dayMonth(b.checkIn)} → ${Fmt.dayMonth(b.checkOut)} · ${b.nights} nuit${b.nights > 1 ? 's' : ''}',
          style: t.bodySmall,
        ),
        Row(children: [
          Expanded(
            child: WamiGhostButton(
              label: 'Refuser',
              onPressed: busy ? null : () => _reject(context, cubit),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: WamiPrimaryButton(label: 'Confirmer', height: 50, loading: busy, onPressed: () => cubit.confirm(b))),
        ]),
      ]),
    );
  }

  Future<void> _reject(BuildContext context, PlanningCubit cubit) async {
    const reasons = ['Complet sur ces dates', 'Travaux dans la chambre', 'Séjour trop court'];
    final reason = await showBizSheet<String>(context, children: (sheet) => [
          Text('Motif du refus', style: Theme.of(sheet).textTheme.titleMedium),
          for (final r in reasons) ListRow(title: r, icon: Icons.close_rounded, onTap: () => Navigator.pop(sheet, r)),
        ]);
    if (reason != null) await cubit.reject(booking, reason);
  }
}
