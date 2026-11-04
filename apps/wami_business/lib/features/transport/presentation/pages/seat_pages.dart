import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/biz_accent.dart';
import '../../../../shared/data_state.dart';
import '../../domain/entities/transport.dart';
import '../cubit/transport_cubits.dart';

Color _seatColor(BuildContext context, SeatState s) => switch (s) {
      SeatState.free => context.wami.glass,
      SeatState.soldApp => BizAccent.glow.withValues(alpha: 0.55),
      SeatState.soldCounter => WamiColors.orangeLight.withValues(alpha: 0.55),
      SeatState.blocked => context.wami.inkMuted.withValues(alpha: 0.25),
      SeatState.boarded => WamiColors.success.withValues(alpha: 0.6),
    };

// ─── Plan des places ─────────────────────────────────────────────────────────

/// Plan partagé avec l'app client : une place vendue ici disparaît aussitôt de la vente en ligne.
class SeatMapPage extends StatelessWidget {
  const SeatMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SeatMapCubit>();
    final t = Theme.of(context).textTheme;
    return BlocConsumer<SeatMapCubit, DataState<Departure>>(
      listenWhen: (a, b) => b.failure != null && a.failure != b.failure,
      listener: (context, s) => showWamiMessage(context, s.failure!.message),
      builder: (context, s) {
        final d = s.data;
        return WamiScreen(
          title: d == null ? 'Places' : '${Fmt.hhmm(d.effectiveAt)} · ${d.line.label}',
          subtitle: d == null ? null : '${d.free} places libres · ${Fmt.fcfa(d.line.price)}',
          glow: BizAccent.glow,
          body: d == null
              ? (s.status == LoadStatus.failure
                  ? WamiErrorView(failure: s.failure!, onRetry: cubit.reload)
                  : const SizedBox(height: 300, child: WamiLoading()))
              : Gap(children: [
                  Wrap(spacing: 12, runSpacing: 6, children: [
                    for (final st in SeatState.values)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(color: _seatColor(context, st), borderRadius: BorderRadius.circular(3)),
                        ),
                        const SizedBox(width: 4),
                        Text(st.label, style: t.bodySmall),
                      ]),
                  ]),
                  GlassCard(child: _SeatGrid(departure: d, onTap: (seat) => _onSeat(context, cubit, seat))),
                  Text('Touchez une place libre pour la vendre au guichet ou la bloquer.', style: t.bodySmall),
                ]),
        );
      },
    );
  }

  Future<void> _onSeat(BuildContext context, SeatMapCubit cubit, Seat seat) async {
    final t = Theme.of(context).textTheme;
    switch (seat.state) {
      case SeatState.free:
        var name = '';
        final action = await showBizSheet<String>(context, children: (sheet) => [
              Text('Place ${seat.number}', style: t.titleMedium),
              WamiTextField(hint: 'Nom du voyageur', icon: Icons.person_outline_rounded, onChanged: (v) => name = v),
              WamiPrimaryButton(label: 'Vendre au guichet', onPressed: () => Navigator.pop(sheet, 'sell')),
              WamiGhostButton(label: 'Bloquer la place', icon: Icons.block_rounded, onPressed: () => Navigator.pop(sheet, 'block')),
            ]);
        if (action == 'sell') {
          if (await cubit.sell(seat.number, name) && context.mounted) showWamiMessage(context, 'Place ${seat.number} vendue.');
        } else if (action == 'block') {
          await cubit.toggleBlocked(seat.number);
        }
      case SeatState.blocked:
        final unblock = await showBizSheet<bool>(context, children: (sheet) => [
              Text('Place ${seat.number} bloquée', style: t.titleMedium),
              WamiPrimaryButton(label: 'Remettre en vente', onPressed: () => Navigator.pop(sheet, true)),
            ]);
        if (unblock == true) await cubit.toggleBlocked(seat.number);
      case SeatState.soldApp:
      case SeatState.soldCounter:
      case SeatState.boarded:
        await showBizSheet<void>(context, children: (_) => [
              Text('Place ${seat.number}', style: t.titleMedium),
              InfoRow('Voyageur', seat.passengerName ?? '—'),
              InfoRow('Statut', seat.state.label),
              InfoRow('Billet', seat.ticketCode ?? '—'),
            ]);
    }
  }
}

/// Bus 2 + 2 avec allée centrale.
class _SeatGrid extends StatelessWidget {
  const _SeatGrid({required this.departure, required this.onTap});
  final Departure departure;
  final ValueChanged<Seat> onTap;

  @override
  Widget build(BuildContext context) {
    final seats = departure.seats;
    final p = context.wami;
    Widget tile(Seat s) => Expanded(
          child: Tooltip(
            message: 'Place ${s.number} · ${s.state.label}',
            child: InkWell(
              onTap: () => onTap(s),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 40,
                margin: const EdgeInsets.all(3),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _seatColor(context, s.state),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: p.glassBorder),
                ),
                child: Text('${s.number}', style: WamiTypography.number(13, color: p.ink)),
              ),
            ),
          ),
        );

    return Column(children: [
      for (var row = 0; row * 4 < seats.length; row++)
        Row(children: [
          for (var c = 0; c < 4; c++) ...[
            if (c == 2) const SizedBox(width: 18),
            if (row * 4 + c < seats.length) tile(seats[row * 4 + c]) else const Expanded(child: SizedBox()),
          ],
        ]),
    ]);
  }
}

// ─── Embarquement ────────────────────────────────────────────────────────────

class BoardingPage extends StatefulWidget {
  const BoardingPage({super.key});

  @override
  State<BoardingPage> createState() => _BoardingPageState();
}

class _BoardingPageState extends State<BoardingPage> {
  String _code = '';
  Seat? _last;

  /// Change de clé pour vider la saisie après chaque billet validé.
  var _inputKey = 0;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SeatMapCubit>();
    final t = Theme.of(context).textTheme;
    return BlocBuilder<SeatMapCubit, DataState<Departure>>(
      builder: (context, s) {
        final d = s.data;
        if (d == null) {
          return Scaffold(
            body: s.status == LoadStatus.failure ? WamiErrorView(failure: s.failure!, onRetry: cubit.reload) : const WamiLoading(),
          );
        }
        return WamiScreen(
          title: 'Embarquement',
          subtitle: '${Fmt.hhmm(d.effectiveAt)} · ${d.line.label}',
          glow: BizAccent.glow,
          body: Gap(children: [
            KpiRow(children: [
              KpiTile(value: '${d.boarded}', label: 'à bord', color: WamiColors.success),
              KpiTile(value: '${d.sold - d.boarded}', label: 'attendus'),
              KpiTile(value: '${d.free}', label: 'libres'),
            ]),
            const SizedBox(height: 4),
            CodeInput(
              key: ValueKey(_inputKey),
              length: 6,
              error: s.failure != null && _last == null,
              onChanged: (v) => setState(() => _code = v),
            ),
            if (_last != null)
              GlassCard(
                borderColor: WamiColors.success,
                child: ListRow(
                  title: '${_last!.passengerName ?? 'Voyageur'} · place ${_last!.number}',
                  subtitle: 'Embarqué',
                  icon: Icons.check_circle_rounded,
                  iconColor: WamiColors.success,
                ),
              )
            else if (s.failure != null)
              Text(s.failure!.message, textAlign: TextAlign.center, style: TextStyle(color: context.wami.danger))
            else
              Text('Code à 6 chiffres du billet. En démo : 300512.', textAlign: TextAlign.center, style: t.bodySmall),
          ]),
          bottom: WamiPrimaryButton(
            label: 'Valider le billet',
            loading: s.busy,
            onPressed: _code.length == 6
                ? () async {
                    final seat = await cubit.board(_code);
                    if (!mounted) return;
                    setState(() {
                      _last = seat;
                      if (seat != null) {
                        _code = '';
                        _inputKey++;
                      }
                    });
                  }
                : null,
          ),
        );
      },
    );
  }
}
