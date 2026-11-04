import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/biz_accent.dart';
import '../../domain/entities/order.dart';
import '../cubit/restaurant_cubits.dart';

/// Onglet « Activité » d'un restaurant : nouvelles → en cuisine → prêtes.
class OrdersBoardPage extends StatelessWidget {
  const OrdersBoardPage({super.key});

  static const _columns = [OrderStatus.incoming, OrderStatus.kitchen, OrderStatus.ready];

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OrdersCubit>();
    return BlocConsumer<OrdersCubit, OrdersState>(
      listenWhen: (a, b) => b.failure != null && a.failure != b.failure,
      listener: (context, s) => showWamiMessage(context, s.failure!.message),
      builder: (context, s) {
        return WamiScreen(
          showBack: false,
          title: 'Commandes',
          subtitle: 'Aujourd’hui',
          glow: BizAccent.glow,
          body: switch (s.status) {
            LoadStatus.idle || LoadStatus.loading => const SizedBox(height: 300, child: WamiLoading()),
            LoadStatus.failure => WamiErrorView(failure: s.failure!, onRetry: cubit.retry),
            LoadStatus.ready => Gap(
                children: [
                  WamiSegmented<OrderStatus>(
                    options: [for (final c in _columns) (c, '${c.label} (${s.of(c).length})')],
                    value: s.column,
                    onChanged: cubit.showColumn,
                  ),
                  if (s.visible.isEmpty)
                    EmptyState(icon: Icons.receipt_long_rounded, message: _emptyMessage(s.column))
                  else
                    for (final o in s.visible) _OrderCard(order: o, now: s.now, busy: s.busyId == o.id),
                ],
              ),
          },
        );
      },
    );
  }

  static String _emptyMessage(OrderStatus c) => switch (c) {
        OrderStatus.incoming => 'Aucune nouvelle commande. Elles arrivent ici avec une alerte.',
        OrderStatus.kitchen => 'Rien en préparation.',
        _ => 'Aucune commande en attente de livreur.',
      };
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.now, required this.busy});
  final FoodOrder order;
  final DateTime now;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cubit = context.read<OrdersCubit>();
    final o = order;
    return ActionCard(
      hot: o.status == OrderStatus.incoming,
      child: Gap(
        gap: 10,
        children: [
          Row(children: [
            Text(o.number, style: t.titleMedium),
            const SizedBox(width: 8),
            Expanded(child: Text(o.customerName, style: t.bodySmall, overflow: TextOverflow.ellipsis)),
            NumberText(Fmt.fcfa(o.total), size: 14),
          ]),
          for (final l in o.lines)
            Text('${l.quantity} × ${l.name}${l.note != null ? ' — ${l.note}' : ''}', style: t.bodyMedium),
          _statusLine(context, o),
          if (busy)
            const SizedBox(height: 50, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
          else
            ..._actions(context, cubit, o),
        ],
      ),
    );
  }

  Widget _statusLine(BuildContext context, FoodOrder o) {
    final t = Theme.of(context).textTheme.bodySmall;
    switch (o.status) {
      case OrderStatus.incoming:
        final toAccept = o.acceptSecondsLeft(now);
        return Text(
          toAccept > 0 ? 'À accepter sous ${Fmt.clock(toAccept)}' : 'Délai dépassé : le client peut annuler',
          style: t?.copyWith(color: toAccept > 30 ? WamiColors.orangeLight : WamiColors.danger),
        );
      case OrderStatus.kitchen:
        final toReady = o.remainingSeconds(now);
        return Row(children: [
          Icon(Icons.timer_outlined, size: 16, color: toReady >= 0 ? BizAccent.glow : WamiColors.danger),
          const SizedBox(width: 6),
          Text(
            toReady >= 0 ? 'Prête dans ${Fmt.clock(toReady)}' : 'En retard de ${Fmt.clock(-toReady)}',
            style: t?.copyWith(color: toReady >= 0 ? BizAccent.soft : WamiColors.danger),
          ),
        ]);
      case OrderStatus.ready:
        return Text(
          o.courierName == null ? 'Recherche d’un livreur WAMI…' : '${o.courierName} arrive pour la récupérer',
          style: t,
        );
      case OrderStatus.pickedUp:
      case OrderStatus.rejected:
        return Text(o.status.label, style: t);
    }
  }

  List<Widget> _actions(BuildContext context, OrdersCubit cubit, FoodOrder o) {
    return switch (o.status) {
      OrderStatus.incoming => [
          Row(children: [
            Expanded(child: WamiGhostButton(label: 'Refuser', onPressed: () => _reject(context, cubit, o))),
            const SizedBox(width: 10),
            Expanded(child: WamiPrimaryButton(label: 'Accepter', height: 50, onPressed: () => _accept(context, cubit, o))),
          ]),
        ],
      OrderStatus.kitchen => [
          Row(children: [
            Expanded(
              child: WamiGhostButton(
                label: '+${PrepRules.extensionMinutes} min',
                icon: Icons.more_time_rounded,
                onPressed: o.canExtend ? () => cubit.extend(o) : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: WamiPrimaryButton(label: 'Prête', height: 50, icon: Icons.check_rounded, onPressed: () => cubit.markReady(o))),
          ]),
        ],
      _ => const [],
    };
  }

  Future<void> _accept(BuildContext context, OrdersCubit cubit, FoodOrder o) async {
    final minutes = await showBizSheet<int>(context, children: (sheet) => [
          Text('Temps de préparation', style: Theme.of(sheet).textTheme.titleMedium),
          Text('Annoncé au client et au livreur. Vous pourrez ajouter ${PrepRules.extensionMinutes} min ${PrepRules.maxExtensions} fois.',
              style: Theme.of(sheet).textTheme.bodySmall),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final m in PrepRules.presets) WamiChip(label: '$m min', selected: false, onTap: () => Navigator.pop(sheet, m)),
          ]),
        ]);
    if (minutes != null) await cubit.accept(o, minutes);
  }

  Future<void> _reject(BuildContext context, OrdersCubit cubit, FoodOrder o) async {
    const reasons = ['Un plat est épuisé', 'Cuisine saturée', 'Fermeture imminente', 'Adresse hors zone'];
    final reason = await showBizSheet<String>(context, children: (sheet) => [
          Text('Pourquoi refuser ?', style: Theme.of(sheet).textTheme.titleMedium),
          Text('Le client est prévenu et remboursé. Des refus fréquents baissent votre visibilité.',
              style: Theme.of(sheet).textTheme.bodySmall),
          for (final r in reasons) ListRow(title: r, icon: Icons.close_rounded, onTap: () => Navigator.pop(sheet, r)),
        ]);
    if (reason != null) await cubit.reject(o, reason);
  }
}
