import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/pro_accent.dart';
import '../../domain/entities/fare.dart';
import '../../domain/entities/mission.dart';

IconData kindIcon(MissionKind k) => switch (k) {
      MissionKind.ride => Icons.local_taxi_rounded,
      MissionKind.parcel => Icons.inventory_2_outlined,
      MissionKind.meal => Icons.restaurant_rounded,
    };

/// Deux points reliés : départ → arrivée.
class StopsCard extends StatelessWidget {
  const StopsCard({super.key, required this.offer});
  final MissionOffer offer;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget stop(Color dot, String title, String sub, {bool glow = false}) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: dot,
                shape: BoxShape.circle,
                boxShadow: glow ? [BoxShadow(color: dot, blurRadius: 10)] : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: t.titleSmall),
                Text(sub, style: t.bodySmall),
              ]),
            ),
          ],
        );
    return GlassCard(
      child: Column(
        children: [
          stop(Colors.white, offer.pickup.label, 'à ${offer.distanceToPickupKm.toStringAsFixed(1).replaceAll('.', ',')} km de vous'),
          const SizedBox(height: 12),
          stop(WamiColors.orangeLight, offer.dropoff.label,
              '${offer.tripKm.toStringAsFixed(1).replaceAll('.', ',')} km · ~${offer.tripMinutes} min',
              glow: true),
        ],
      ),
    );
  }
}

/// Proposition de mission avec compte à rebours.
class OfferSheet extends StatelessWidget {
  const OfferSheet({
    super.key,
    required this.offer,
    required this.remaining,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
  });

  final MissionOffer offer;
  final int remaining;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return WamiSheet(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(spacing: 6, children: [
                    WamiTag(offer.kind.label, tint: ProAccent.glow),
                    if (offer.parcelSize != null) WamiTag('Colis ${offer.parcelSize}', tint: ProAccent.glow),
                    if (offer.fragile) const WamiTag('Fragile', tint: WamiColors.glowHebergement),
                  ]),
                  const SizedBox(height: 6),
                  NumberText(Fmt.fcfa(offer.netEarning), size: 30),
                  Text(
                    offer.kind == MissionKind.ride
                        ? 'Votre gain net · client paie ${Fmt.fcfa(offer.clientPrice)}'
                        : 'Votre gain net',
                    style: t.bodySmall,
                  ),
                ],
              ),
            ),
            CountdownRing(remaining: remaining, total: offer.acceptSeconds),
          ],
        ),
        StopsCard(offer: offer),
        if (offer.cashToCollect > 0)
          GlassCard(
            borderColor: WamiColors.glowHebergement.withValues(alpha: 0.4),
            child: Row(children: [
              const Icon(Icons.payments_outlined, color: WamiColors.glowHebergement),
              const SizedBox(width: 10),
              const Expanded(child: Text('À encaisser au destinataire')),
              NumberText(Fmt.fcfa(offer.cashToCollect), size: 15),
            ]),
          ),
        Row(children: [
          RatingText(offer.customerRating, size: 12),
          const SizedBox(width: 6),
          Text('Client', style: t.bodySmall),
          const Spacer(),
          Icon(Icons.account_balance_wallet_outlined, size: 16, color: context.wami.orangeStrong),
          const SizedBox(width: 6),
          Text('Payé par ${offer.payment.label.toLowerCase()}', style: t.bodySmall),
        ]),
        Row(children: [
          SizedBox(width: 110, child: WamiGhostButton(label: 'Refuser', onPressed: busy ? null : onDecline, height: 56)),
          const SizedBox(width: 10),
          Expanded(child: WamiPrimaryButton(label: 'Accepter', loading: busy, onPressed: onAccept)),
        ]),
      ],
    );
  }
}

/// Compteur d'attente (identique à celui que voit le client).
class WaitingRing extends StatelessWidget {
  const WaitingRing({super.key, required this.waited, required this.policy});
  final int waited;
  final FarePolicy policy;

  @override
  Widget build(BuildContext context) {
    final fee = policy.waitingFee(waited);
    final free = policy.freeLeft(waited);
    return Column(
      children: [
        const SectionLabel('Attente du client'),
        const SizedBox(height: 8),
        SizedBox.square(
          dimension: 170,
          child: CustomPaint(
            painter: _WaitPainter(waited: waited, free: policy.freeWaitingSeconds, track: context.wami.ink.withValues(alpha: 0.1)),
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                NumberText(Fmt.clock(waited), size: 32),
                const SizedBox(height: 4),
                if (fee > 0) WamiTag('+ ${Fmt.fcfa(fee)}') else WamiTag('Gratuit ${Fmt.clock(free)}', tint: WamiColors.white),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          fee > 0
              ? 'Attente facturée ${Fmt.fcfa(policy.waitingRatePerMinute)}/min · le client voit le même compteur'
              : 'Attente gratuite · le client voit le même compteur',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _WaitPainter extends CustomPainter {
  _WaitPainter({required this.waited, required this.free, required this.track});
  final int waited;
  final int free;
  final Color track;
  static const _span = 300;

  @override
  void paint(Canvas canvas, Size size) {
    final r = (Offset.zero & size).deflate(8);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, math.pi * 2, false, p..color = track);
    const start = -math.pi / 2;
    final freeSweep = math.min(waited, free) / _span * math.pi * 2;
    canvas.drawArc(r, start, freeSweep, false, p..color = const Color(0xCCFFFFFF));
    if (waited > free) {
      final paid = (math.min(waited, _span) - free) / _span * math.pi * 2;
      canvas.drawArc(r, start + freeSweep, paid, false, p..color = WamiColors.orangeLight);
    }
  }

  @override
  bool shouldRepaint(_WaitPainter old) => old.waited != waited;
}

/// Bandeau de pause, visible aussi chez le client.
class PauseBanner extends StatelessWidget {
  const PauseBanner({super.key, required this.seconds, required this.policy});
  final int seconds;
  final FarePolicy policy;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: WamiColors.glowHebergement.withValues(alpha: 0.55),
      gradient: LinearGradient(colors: [
        WamiColors.glowHebergement.withValues(alpha: 0.2),
        WamiColors.glowHebergement.withValues(alpha: 0.04),
      ]),
      child: Row(children: [
        const IconBadge(Icons.pause_rounded, color: WamiColors.glowHebergement, size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Course en pause', style: Theme.of(context).textTheme.titleSmall),
            Text(
              policy.pauseBilled ? 'Le client est prévenu · ${Fmt.fcfa(policy.pauseRatePerMinute)}/min (à valider)' : 'Le client est prévenu',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ]),
        ),
        NumberText(Fmt.clock(seconds), size: 18, color: WamiColors.glowHebergement),
      ]),
    );
  }
}

/// Dock de contact client (message + appel), affiché avant le démarrage seulement.
class CustomerDock extends StatelessWidget {
  const CustomerDock({super.key, required this.name, required this.onMessage, required this.onCall});
  final String name;
  final VoidCallback onMessage;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: GlassCard(
          onTap: onMessage,
          radius: WamiRadius.pill,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 18, color: context.wami.orangeStrong),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Écrire à ${name.split(' ').first}…',
                  overflow: TextOverflow.ellipsis, style: TextStyle(color: context.wami.inkMuted, fontSize: 13.5)),
            ),
          ]),
        ),
      ),
      const SizedBox(width: 10),
      GlowOrbButton(icon: Icons.call_rounded, tooltip: 'Appeler', onPressed: onCall),
    ]);
  }
}
