import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/places.dart';
import '../../../../shared/pro_accent.dart';
import '../../../../shared/routes.dart';
import '../../domain/entities/mission.dart';
import '../bloc/missions_bloc.dart';
import '../cubit/direct_ride_cubit.dart';

/// Prendre un client dans la rue : choisir la destination, voir le prix, démarrer.
/// Paiement en espèces uniquement (règle du serveur).
class DirectRidePage extends StatelessWidget {
  const DirectRidePage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return BlocConsumer<DirectRideCubit, DirectRideState>(
      listenWhen: (a, b) => b.failure != null && a.failure != b.failure,
      listener: (context, s) => showWamiMessage(context, s.failure!.message),
      builder: (context, s) {
        final e = s.estimate;
        return WamiScreen(
          title: 'Course directe',
          glow: ProAccent.glow,
          body: Gap(
            children: [
              Text('Départ : votre position. Paiement en espèces.', style: t.bodySmall),
              const SectionLabel('Destination'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final p in [...Places.quarters, ...Places.cities.where((c) => !Places.quarters.any((q) => q.name == c.name))])
                  WamiChip(
                    label: p.name,
                    selected: s.destination?.dropoffLabel == p.name,
                    onTap: () => context.read<DirectRideCubit>().choose(
                          DirectRideRequest(dropoffLabel: p.name, dropoffLat: p.lat, dropoffLng: p.lng),
                        ),
                  ),
              ]),
              Text('Positions approximatives : un vrai sélecteur d’adresse viendra avec le service de géocodage.',
                  style: t.bodySmall?.copyWith(fontSize: 11.5)),
              if (s.busy && e == null) const SizedBox(height: 60, child: WamiLoading()),
              if (e != null)
                GlassGroup(children: [
                  InfoRow('Prix estimé', Fmt.fcfa(e.price), strong: true),
                  InfoRow('Tarif minimum', Fmt.fcfa(e.minimumFare)),
                  InfoRow('Distance', '${e.distanceKm.toStringAsFixed(1).replaceAll('.', ',')} km'),
                  InfoRow('Durée', '${e.durationMin} min'),
                  if (e.surgeMultiplier > 1) InfoRow('Forte demande', '× ${e.surgeMultiplier.toStringAsFixed(1).replaceAll('.', ',')}'),
                ]),
            ],
          ),
          bottom: WamiPrimaryButton(
            label: 'Démarrer la course',
            icon: Icons.play_arrow_rounded,
            loading: s.busy && e != null,
            onPressed: e == null
                ? null
                : () async {
                    final mission = await context.read<DirectRideCubit>().begin();
                    if (mission != null && context.mounted) {
                      context.read<MissionsBloc>().add(DirectRideBegan(mission));
                      context.pushReplacement(ProRoutes.mission);
                    }
                  },
          ),
        );
      },
    );
  }
}
