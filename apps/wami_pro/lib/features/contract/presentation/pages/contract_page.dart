import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/data_state.dart';
import '../../../../shared/pro_accent.dart';
import '../../domain/entities/contract.dart';
import '../cubit/contract_cubit.dart';

/// Contrat de location-vente : avancement, prochaine échéance, échéancier.
class ContractPage extends StatelessWidget {
  const ContractPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return BlocBuilder<ContractCubit, DataState<VehicleContract>>(
      builder: (context, s) {
        final c = s.data;
        return WamiScreen(
          title: 'Mon contrat',
          glow: ProAccent.glow,
          body: switch (s.status) {
            LoadStatus.idle || LoadStatus.loading => const SizedBox(height: 300, child: WamiLoading()),
            LoadStatus.failure => Text(s.failure?.message ?? 'Contrat indisponible.', style: t.bodySmall),
            LoadStatus.ready when c == null => Text('Vous n’avez aucun contrat de véhicule en cours.', style: t.bodySmall),
            _ => Gap(children: _content(context, c!)),
          },
        );
      },
    );
  }

  List<Widget> _content(BuildContext context, VehicleContract c) {
    final t = Theme.of(context).textTheme;
    return [
      if (c.blocked)
        GlassCard(
          borderColor: WamiColors.danger.withValues(alpha: 0.5),
          child: const Text('Compte bloqué pour échéances impayées : plus de missions ni de retrait tant que le retard n’est pas réglé.'),
        ),
      GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('Remboursé', style: t.titleSmall)),
            WamiTag(c.status),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: c.progress, minHeight: 8, color: WamiColors.orangeLight, backgroundColor: Colors.white12),
          ),
          const SizedBox(height: 10),
          InfoRow('Total du contrat', Fmt.fcfa(c.total)),
          InfoRow('Déjà payé', Fmt.fcfa(c.paid), valueColor: WamiColors.success),
          InfoRow('Reste à payer', Fmt.fcfa(c.remaining), strong: true),
          if (c.unpaidCount > 0) InfoRow('Échéances impayées', '${c.unpaidCount}', valueColor: WamiColors.danger),
          if (c.byRevenue) Text('Remboursement prélevé sur vos revenus.', style: t.bodySmall),
        ]),
      ),
      if (c.nextDueDate != null && c.nextAmount != null)
        GlassCard(
          child: ListRow(
            title: 'Prochaine échéance',
            subtitle: Fmt.relativeDay(c.nextDueDate!),
            icon: Icons.event_rounded,
            iconColor: ProAccent.glow,
            trailing: NumberText(Fmt.fcfa(c.nextAmount!), size: 15),
          ),
        ),
      const SectionLabel('Échéancier'),
      GlassGroup(children: [
        for (final i in c.installments)
          ListRow(
            title: 'Échéance ${i.number} · ${Fmt.fcfa(i.amount)}',
            subtitle: Fmt.relativeDay(i.dueDate),
            icon: i.state == InstallmentState.paid ? Icons.check_circle_rounded : Icons.schedule_rounded,
            iconColor: switch (i.state) {
              InstallmentState.paid => WamiColors.success,
              InstallmentState.late => WamiColors.danger,
              _ => null,
            },
            trailing: WamiTag(i.state.label),
          ),
      ]),
    ];
  }
}
