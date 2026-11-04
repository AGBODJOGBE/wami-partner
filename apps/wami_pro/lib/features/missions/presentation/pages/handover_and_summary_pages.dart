import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/routes.dart';
import '../../domain/entities/mission.dart';
import '../bloc/missions_bloc.dart';

/// Remise d'une livraison avec le code du destinataire (et encaissement éventuel).
class HandoverPage extends StatefulWidget {
  const HandoverPage({super.key});

  @override
  State<HandoverPage> createState() => _HandoverPageState();
}

class _HandoverPageState extends State<HandoverPage> {
  String _code = '';
  PaymentMode _mode = PaymentMode.cash;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MissionsBloc, MissionsState>(
      listenWhen: (a, b) => (b.failure != null && a.failure != b.failure) || (a.receipt == null && b.receipt != null),
      listener: (context, s) {
        if (s.failure != null) showWamiMessage(context, s.failure!.message);
        if (s.receipt != null) context.pushReplacement(ProRoutes.summary);
      },
      builder: (context, s) {
        final o = s.active?.offer;
        if (o == null) return const Scaffold(body: WamiLoading());
        return WamiScreen(
          title: 'Remise',
          subtitle: o.dropoff.contactName ?? o.dropoff.label,
          glow: WamiColors.glowLivraison,
          body: Gap(
            children: [
              const Center(child: SectionLabel('Code de remise du destinataire')),
              CodeInput(onChanged: (v) => setState(() => _code = v)),
              Text('Le destinataire a reçu ce code par SMS. Il prouve la livraison.',
                  textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
              if (o.cashToCollect > 0)
                GlassCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Row(children: [
                      const Expanded(child: Text('Encaisser', style: TextStyle(fontWeight: FontWeight.w600))),
                      NumberText(Fmt.fcfa(o.cashToCollect), size: 20),
                    ]),
                    const SizedBox(height: 10),
                    WamiSegmented<PaymentMode>(
                      options: const [(PaymentMode.cash, 'Espèces'), (PaymentMode.mobileMoney, 'Mobile Money')],
                      value: _mode,
                      onChanged: (m) => setState(() => _mode = m),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _mode == PaymentMode.cash
                          ? 'La somme sera déduite de votre solde puis reversée à l’expéditeur.'
                          : 'Le destinataire paie sur son téléphone : rien à reverser.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11.5),
                    ),
                  ]),
                ),
            ],
          ),
          bottom: WamiPrimaryButton(
            label: 'Confirmer la remise',
            icon: Icons.check_rounded,
            loading: s.busy,
            onPressed: _code.length == 4
                ? () => context.read<MissionsBloc>().add(HandoverConfirmed(code: _code, collectedWith: _mode))
                : null,
          ),
        );
      },
    );
  }
}

/// Fin de mission : détail transparent et note du client.
class MissionSummaryPage extends StatefulWidget {
  const MissionSummaryPage({super.key});

  @override
  State<MissionSummaryPage> createState() => _MissionSummaryPageState();
}

class _MissionSummaryPageState extends State<MissionSummaryPage> {
  int _stars = 5;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<MissionsBloc>().state;
    final r = s.receipt;
    if (r == null) return const Scaffold(body: WamiLoading());
    final percent = (s.policy.commissionRate * 100).round();
    return PopScope(
      canPop: false,
      child: WamiScreen(
        showBack: false,
        body: WamiSuccessView(
          positive: true,
          icon: Icons.check_rounded,
          title: r.kind == MissionKind.ride ? 'Course terminée' : 'Livraison effectuée',
          message: 'Payé par ${r.payment.label.toLowerCase()}',
          children: [
            GlassGroup(children: [
              InfoRow(r.kind.label, Fmt.fcfa(r.clientPrice)),
              if (r.waitingFee > 0) InfoRow('Attente facturée', Fmt.fcfa(r.waitingFee)),
              if (r.pauseFee > 0) InfoRow('Pause', Fmt.fcfa(r.pauseFee)),
              InfoRow('Payé par le client', Fmt.fcfa(r.total)),
              InfoRow('Commission WAMI · $percent % à valider', '− ${Fmt.fcfa(r.commission)}', valueColor: context.wami.danger),
              InfoRow('Votre gain', Fmt.fcfa(r.net), strong: true, valueColor: WamiColors.success),
            ]),
            if (r.commissionDueFromPartner) ...[
              const SizedBox(height: 10),
              GlassCard(
                borderColor: WamiColors.glowHebergement.withValues(alpha: 0.4),
                child: Text('Espèces : encaissez ${Fmt.fcfa(r.total)}. La commission est retenue sur votre solde.'),
              ),
            ],
            if (r.cashCollected > 0) ...[
              const SizedBox(height: 10),
              GlassCard(child: Text('Encaissé pour l’expéditeur : ${Fmt.fcfa(r.cashCollected)}')),
            ],
            const SizedBox(height: 16),
            const SectionLabel('Noter le client'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    tooltip: '$i étoile${i > 1 ? 's' : ''}',
                    iconSize: 34,
                    onPressed: () => setState(() => _stars = i),
                    icon: Icon(
                      i <= _stars ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: i <= _stars ? WamiColors.orangeLight : Colors.white30,
                    ),
                  ),
              ],
            ),
          ],
        ),
        bottom: WamiPrimaryButton(
          label: 'Prochaine mission',
          onPressed: () {
            context.read<MissionsBloc>().add(ReceiptClosed(stars: _stars));
            context.go(ProRoutes.missions);
          },
        ),
      ),
    );
  }
}
