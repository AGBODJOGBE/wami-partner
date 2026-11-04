import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/background_location_disclosure.dart';
import '../../../../shared/routes.dart';
import '../bloc/missions_bloc.dart';
import '../widgets/mission_widgets.dart';

/// Onglet Missions : en ligne / hors ligne, demande en cours, mission active.
class MissionsHomePage extends StatelessWidget {
  const MissionsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MissionsBloc>();
    return BlocConsumer<MissionsBloc, MissionsState>(
      listenWhen: (a, b) =>
          (b.failure != null && a.failure != b.failure) || (a.active == null && b.active != null),
      listener: (context, s) {
        if (s.failure != null) showWamiMessage(context, s.failure!.message);
        if (s.active != null) context.push(ProRoutes.mission);
      },
      builder: (context, s) {
        if (s.day == null) {
          return Scaffold(
            body: s.status == LoadStatus.failure
                ? WamiErrorView(failure: s.failure ?? const UnexpectedFailure(), onRetry: () => bloc.add(const MissionsStarted()))
                : const WamiLoading(),
          );
        }
        final day = s.day!;
        final since = day.onlineSince;
        return Scaffold(
          body: Stack(
            children: [
              const Positioned.fill(child: RouteMapView(showRoute: false)),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        StatusPill(
                          live: day.online,
                          child: Text(day.online
                              ? 'En ligne${since == null ? '' : ' · ${Fmt.duration(s.now.difference(since).inMinutes)}'}'
                              : 'Hors ligne'),
                        ),
                        const Spacer(),
                        StatusPill(child: NumberText(Fmt.fcfa(day.earnings), size: 14)),
                      ]),
                      if (day.online && day.hotZone != null) ...[
                        const SizedBox(height: 10),
                        StatusPill(
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.local_fire_department_rounded, size: 16, color: WamiColors.orangeLight),
                            const SizedBox(width: 6),
                            Text('Forte demande · ${day.hotZone}'),
                          ]),
                        ),
                      ],
                      if (s.active != null) ...[
                        const SizedBox(height: 10),
                        StatusPill(
                          onTap: () => context.push(ProRoutes.mission),
                          child: Text('Mission en cours · ${s.active!.offer.kind.label} — reprendre'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 84),
                  child: s.offer != null
                      ? OfferSheet(
                          offer: s.offer!,
                          remaining: s.offerRemaining,
                          busy: s.busy,
                          onAccept: () => bloc.add(const OfferAccepted()),
                          onDecline: () => bloc.add(const OfferDeclined()),
                        )
                      : WamiSheet(
                          children: [
                            Center(
                              child: PowerButton(
                                online: day.online,
                                onTap: () async {
                                  if (!day.online) await BackgroundLocationDisclosure.show(context);
                                  if (context.mounted) bloc.add(const OnlineToggled());
                                },
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (day.online)
                              Text('Les demandes proches de vous vont arriver ici.',
                                  textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
                            KpiRow(children: [
                              KpiTile(value: '${day.missions}', label: 'missions'),
                              KpiTile(value: day.rating.toStringAsFixed(1).replaceAll('.', ','), label: 'note', color: WamiColors.star),
                              KpiTile(value: '${(day.acceptanceRate * 100).round()} %', label: 'acceptées'),
                            ]),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
