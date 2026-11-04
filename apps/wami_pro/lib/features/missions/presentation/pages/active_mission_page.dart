import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/photo_picker.dart';
import '../../../../shared/routes.dart';
import '../../domain/entities/fare.dart';
import '../../domain/entities/mission.dart';
import '../bloc/missions_bloc.dart';
import '../widgets/mission_widgets.dart';

/// Mission en cours. Le panneau change selon l'étape :
/// vers le client → sur place (attente + code, ou collecte) → en course / en route → fin.
class ActiveMissionPage extends StatelessWidget {
  const ActiveMissionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MissionsBloc, MissionsState>(
      listenWhen: (a, b) => (b.failure != null && a.failure != b.failure) || (a.receipt == null && b.receipt != null),
      listener: (context, s) {
        if (s.failure != null) showWamiMessage(context, s.failure!.message);
        // Seul l'écran visible navigue (la page de remise peut être au-dessus).
        if (s.receipt != null && (ModalRoute.of(context)?.isCurrent ?? true)) context.pushReplacement(ProRoutes.summary);
      },
      builder: (context, s) {
        final m = s.active;
        if (m == null) return const Scaffold(body: WamiLoading());
        final onTrip = m.stage == MissionStage.inProgress || m.stage == MissionStage.paused;
        return Scaffold(
          body: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 480,
                child: RouteMapView(progress: onTrip ? m.progress(s.now) : null),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(children: [
                    WamiIconButton(icon: Icons.keyboard_arrow_down_rounded, tooltip: 'Réduire', onPressed: () => context.pop()),
                    const SizedBox(width: 10),
                    Expanded(child: StatusPill(live: true, child: Text(_headline(m), overflow: TextOverflow.ellipsis))),
                  ]),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: WamiSheet(key: ValueKey(m.stage), children: _panel(context, s, m)),
              ),
            ],
          ),
        );
      },
    );
  }

  String _headline(ActiveMission m) => switch (m.stage) {
        MissionStage.toPickup => 'Vers ${m.offer.pickup.label}',
        MissionStage.atPickup => m.offer.kind.isDelivery ? 'Collecte en cours' : 'Sur place · attente du client',
        MissionStage.inProgress => 'Vers ${m.offer.dropoff.label}',
        MissionStage.paused => 'Course en pause',
        MissionStage.completed => 'Terminé',
        MissionStage.cancelled => 'Annulée',
      };

  List<Widget> _panel(BuildContext context, MissionsState s, ActiveMission m) {
    final bloc = context.read<MissionsBloc>();
    final o = m.offer;
    void soon(String what) => showWamiMessage(context, '$what : à brancher');

    switch (m.stage) {
      case MissionStage.toPickup:
        return [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SectionLabel(o.kind == MissionKind.ride ? 'Prise en charge' : 'Collecte'),
                Text([o.pickup.label, o.pickup.address].where((e) => e.isNotEmpty).join(' · '), style: Theme.of(context).textTheme.titleSmall),
              ]),
            ),
            WamiIconButton(icon: Icons.navigation_rounded, tooltip: 'Ouvrir dans Google Maps', onPressed: () => soon('Navigation')),
          ]),
          if (o.pickup.note != null)
            GlassCard(child: Text('« ${o.pickup.note} »', style: Theme.of(context).textTheme.bodyMedium)),
          CustomerDock(
            name: o.pickup.contactName ?? o.customerName,
            onMessage: () => soon('Messagerie'),
            onCall: () => soon('Appel masqué'),
          ),
          WamiPrimaryButton(
            label: switch (o.kind) {
              MissionKind.ride => 'Je suis arrivé',
              MissionKind.parcel => 'Je suis au point de collecte',
              MissionKind.meal => 'Je suis au restaurant',
            },
            icon: Icons.flag_rounded,
            loading: s.busy,
            onPressed: () => bloc.add(const ArrivedPressed()),
          ),
        ];

      case MissionStage.atPickup:
        if (o.kind.isDelivery) return [_PickupPanel(mission: m, busy: s.busy)];
        return [_RideStartPanel(waited: m.waitedSeconds(s.now), policy: s.policy, name: o.customerName, busy: s.busy)];

      case MissionStage.inProgress:
      case MissionStage.paused:
        final fare = s.liveFare;
        return [
          if (m.stage == MissionStage.paused) PauseBanner(seconds: m.pausedSeconds(s.now), policy: s.policy),
          GlassCard(
            child: Column(children: [
              Row(children: [
                Expanded(child: Text(o.dropoff.label, style: Theme.of(context).textTheme.titleSmall)),
                NumberText('${(o.tripMinutes * (1 - m.progress(s.now))).ceil()} min', size: 14),
              ]),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: m.progress(s.now),
                  minHeight: 6,
                  color: WamiColors.orangeLight,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              if (fare != null && o.kind == MissionKind.ride) ...[
                const SizedBox(height: 10),
                Row(children: [
                  Text('Total en cours', style: Theme.of(context).textTheme.bodySmall),
                  const Spacer(),
                  NumberText(Fmt.fcfa(fare.total), size: 15),
                ]),
              ],
            ]),
          ),
          // Pendant la course : plus d'appel ni de message.
          if (o.kind == MissionKind.ride) ...[
            Row(children: [
              Expanded(child: WamiGhostButton(label: 'Urgence', icon: Icons.sos_rounded, onPressed: () => soon('Urgence'))),
              const SizedBox(width: 10),
              Expanded(
                child: WamiGhostButton(
                  label: 'Terminer',
                  icon: Icons.flag_rounded,
                  onPressed: s.busy ? null : () => bloc.add(const CompleteRequested()),
                ),
              ),
            ]),
            WamiPrimaryButton(
              label: m.stage == MissionStage.paused ? 'Reprendre la course' : 'Mettre en pause',
              icon: m.stage == MissionStage.paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              loading: s.busy,
              onPressed: () => bloc.add(const PauseToggled()),
            ),
          ] else
            WamiPrimaryButton(
              label: 'Je suis chez le destinataire',
              icon: Icons.flag_rounded,
              onPressed: () => context.push(ProRoutes.handover),
            ),
        ];

      case MissionStage.completed:
      case MissionStage.cancelled:
        return const [SizedBox(height: 120, child: WamiLoading())];
    }
  }
}

/// Course : compteur d'attente puis démarrage (le serveur n'exige pas de code du client).
class _RideStartPanel extends StatefulWidget {
  const _RideStartPanel({required this.waited, required this.policy, required this.name, required this.busy});
  final int waited;
  final FarePolicy policy;
  final String name;
  final bool busy;

  @override
  State<_RideStartPanel> createState() => _RideStartPanelState();
}

class _RideStartPanelState extends State<_RideStartPanel> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WaitingRing(waited: widget.waited, policy: widget.policy),
        const SizedBox(height: 12),
        CustomerDock(name: widget.name, onMessage: () {}, onCall: () {}),
        const SizedBox(height: 12),
        if (widget.waited >= widget.policy.noShowCancelSeconds)
          TextButton(onPressed: () {}, child: const Text('Client absent : annuler avec frais (à valider)')),
        const SizedBox(height: 6),
        WamiPrimaryButton(
          label: 'Démarrer la course',
          icon: Icons.play_arrow_rounded,
          loading: widget.busy,
          onPressed: () => context.read<MissionsBloc>().add(const StartRequested()),
        ),
      ],
    );
  }
}

/// Livraison : liste de contrôle et photo à la collecte.
class _PickupPanel extends StatefulWidget {
  const _PickupPanel({required this.mission, required this.busy});
  final ActiveMission mission;
  final bool busy;

  @override
  State<_PickupPanel> createState() => _PickupPanelState();
}

class _PickupPanelState extends State<_PickupPanel> {
  final _checked = <String>{};
  String? _photoPath;

  @override
  Widget build(BuildContext context) {
    final o = widget.mission.offer;
    final items = PickupChecklist.itemsFor(o);
    final needPhoto = PickupChecklist.photoRequired(o);
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Expanded(child: Text(o.kind == MissionKind.meal ? 'Commande n° ${o.orderNumber}' : 'Collecte du colis', style: t.titleMedium)),
          WamiTag(o.kind == MissionKind.meal ? 'Retrait' : 'Étape 1/2', tint: WamiColors.glowLivraison),
        ]),
        if (o.items.isNotEmpty) ...[
          const SizedBox(height: 8),
          GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final it in o.items) Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text(it)),
              Text('Déjà payé par le client · rien à encaisser', style: t.bodySmall),
            ]),
          ),
        ],
        const SizedBox(height: 10),
        GlassGroup(children: [
          for (final it in items)
            CheckboxListTile(
              value: _checked.contains(it),
              onChanged: (v) => setState(() => v == true ? _checked.add(it) : _checked.remove(it)),
              title: Text(it, style: t.titleSmall),
              activeColor: WamiColors.orange,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          if (needPhoto)
            ListRow(
              title: _photoPath != null ? 'Photo prise' : 'Photo du colis',
              subtitle: 'Protège le livreur et l’expéditeur en cas de litige',
              icon: _photoPath != null ? Icons.check_circle_rounded : Icons.photo_camera_outlined,
              iconColor: _photoPath != null ? WamiColors.success : null,
              onTap: () async {
                final path = await PhotoPicker.camera();
                if (path != null) setState(() => _photoPath = path);
              },
            ),
        ]),
        const SizedBox(height: 12),
        WamiPrimaryButton(
          label: o.kind == MissionKind.meal ? 'Repas récupéré' : 'Colis récupéré',
          loading: widget.busy,
          onPressed: () => context.read<MissionsBloc>().add(
            PickupConfirmed(checked: {..._checked}, photoTaken: _photoPath != null, photoPath: _photoPath),
          ),
        ),
      ],
    );
  }
}
