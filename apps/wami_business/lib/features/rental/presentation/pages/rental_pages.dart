import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/biz_accent.dart';
import '../../../../shared/data_state.dart';
import '../../domain/entities/rental.dart';
import '../cubit/rental_cubits.dart';

String _slotLabel(DateTime d) => '${Fmt.relativeDay(d)} à ${Fmt.hhmm(d)}';

bool _newFailure<T>(DataState<T> a, DataState<T> b) => b.failure != null && a.failure != b.failure;

// ─── Activité : demandes de visite ──────────────────────────────────────────

class VisitsPage extends StatelessWidget {
  const VisitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VisitsCubit>();
    final t = Theme.of(context).textTheme;
    return BlocConsumer<VisitsCubit, DataState<VisitsData>>(
      listenWhen: _newFailure,
      listener: (context, s) => showWamiMessage(context, s.failure!.message),
      builder: (context, s) {
        final d = s.data;
        final now = DateTime.now();
        return WamiScreen(
          showBack: false,
          title: 'Visites',
          glow: BizAccent.glow,
          body: d == null
              ? (s.status == LoadStatus.failure
                  ? WamiErrorView(failure: s.failure!, onRetry: cubit.reload)
                  : const SizedBox(height: 300, child: WamiLoading()))
              : Gap(children: [
                  SectionLabel('Demandes', trailing: d.pending.isEmpty ? null : WamiTag('${d.pending.length}', tint: WamiColors.orangeLight)),
                  if (d.pending.isEmpty)
                    const EmptyState(icon: Icons.event_available_rounded, message: 'Aucune demande de visite en attente.')
                  else
                    for (final v in d.pending)
                      ActionCard(
                        hot: true,
                        child: Gap(gap: 10, children: [
                          Text(v.visitorName, style: t.titleMedium),
                          Text('${v.listingTitle}\nSouhaite visiter ${_slotLabel(v.requestedAt)}', style: t.bodySmall),
                          if (!VisitSlots.fits(v.requestedAt, d.windows))
                            Text('Hors de vos disponibilités', style: t.bodySmall?.copyWith(color: WamiColors.orangeLight)),
                          Row(children: [
                            Expanded(child: WamiGhostButton(label: 'Refuser', onPressed: s.busy ? null : () => cubit.decline(v))),
                            const SizedBox(width: 8),
                            Expanded(
                              child: WamiGhostButton(
                                label: 'Autre créneau',
                                onPressed: s.busy ? null : () => _propose(context, cubit, v, d.windows),
                              ),
                            ),
                          ]),
                          WamiPrimaryButton(label: 'Accepter', height: 50, loading: s.busy, onPressed: () => cubit.accept(v)),
                        ]),
                      ),
                  const SectionLabel('À venir'),
                  if (d.upcoming(now).isEmpty)
                    Text('Aucune visite planifiée.', style: t.bodySmall)
                  else
                    GlassGroup(children: [
                      for (final v in d.upcoming(now))
                        ListRow(
                          title: '${v.visitorName} · ${_slotLabel(v.slot)}',
                          subtitle: '${v.listingTitle} · ${v.status.label}',
                          icon: v.status == VisitStatus.accepted ? Icons.check_circle_rounded : Icons.schedule_rounded,
                          iconColor: v.status == VisitStatus.accepted ? WamiColors.success : BizAccent.glow,
                        ),
                    ]),
                ]),
        );
      },
    );
  }

  Future<void> _propose(BuildContext context, VisitsCubit cubit, VisitRequest v, List<AvailabilityWindow> windows) async {
    final slots = VisitSlots.next(windows, DateTime.now());
    final slot = await showBizSheet<DateTime>(context, children: (sheet) => [
          Text('Proposer un créneau', style: Theme.of(sheet).textTheme.titleMedium),
          if (slots.isEmpty)
            Text('Ajoutez d’abord vos disponibilités dans l’onglet Biens.', style: Theme.of(sheet).textTheme.bodySmall)
          else
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in slots) WamiChip(label: _slotLabel(s), selected: false, onTap: () => Navigator.pop(sheet, s)),
            ]),
        ]);
    if (slot != null) await cubit.propose(v, slot);
  }
}

// ─── Offre : biens et disponibilités ────────────────────────────────────────

class ListingsPage extends StatelessWidget {
  const ListingsPage({super.key, required this.establishmentId});
  final String establishmentId;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ListingsCubit>();
    final t = Theme.of(context).textTheme;
    return BlocConsumer<ListingsCubit, DataState<ListingsData>>(
      listenWhen: _newFailure,
      listener: (context, s) => showWamiMessage(context, s.failure!.message),
      builder: (context, s) {
        final d = s.data;
        return WamiScreen(
          showBack: false,
          title: 'Biens',
          glow: BizAccent.glow,
          body: d == null
              ? (s.status == LoadStatus.failure
                  ? WamiErrorView(failure: s.failure!, onRetry: () => cubit.load(establishmentId))
                  : const SizedBox(height: 300, child: WamiLoading()))
              : Gap(children: [
                  for (final l in d.listings)
                    GlassCard(
                      child: Gap(gap: 8, children: [
                        Row(children: [
                          const ServiceIllustration(ServiceArt.appartement, size: 44),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(l.title, style: t.titleSmall),
                              Text('${l.district} · ${l.rooms} pièce${l.rooms > 1 ? 's' : ''}', style: t.bodySmall),
                            ]),
                          ),
                          NumberText('${Fmt.fcfa(l.monthlyRent)}/mois', size: 13),
                        ]),
                        ToggleRow(
                          title: l.rented ? 'Loué' : 'Disponible',
                          subtitle: l.rented ? 'Masqué des recherches' : 'Visible, demandes de visite ouvertes',
                          value: !l.rented,
                          onChanged: s.busy ? (_) {} : (_) => cubit.toggleRented(l),
                        ),
                      ]),
                    ),
                  SectionLabel(
                    'Disponibilités pour les visites',
                    trailing: TextButton(onPressed: () => _addWindow(context, cubit), child: const Text('Ajouter')),
                  ),
                  if (d.windows.isEmpty)
                    Text('Sans disponibilités, vous ne pouvez pas proposer de créneau.', style: t.bodySmall)
                  else
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final w in d.windows)
                        InputChip(label: Text(w.label), onDeleted: s.busy ? null : () => cubit.removeWindow(w)),
                    ]),
                ]),
        );
      },
    );
  }

  Future<void> _addWindow(BuildContext context, ListingsCubit cubit) async {
    final w = await showBizSheet<AvailabilityWindow>(context, children: (_) => const [_WindowEditor()]);
    if (w != null) await cubit.addWindow(w);
  }
}

class _WindowEditor extends StatefulWidget {
  const _WindowEditor();

  @override
  State<_WindowEditor> createState() => _WindowEditorState();
}

class _WindowEditorState extends State<_WindowEditor> {
  int _day = DateTime.saturday;
  int _start = 9;
  int _end = 12;

  @override
  Widget build(BuildContext context) {
    return Gap(children: [
      Text('Nouvelle plage de visite', style: Theme.of(context).textTheme.titleMedium),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (var d = 1; d <= 7; d++)
          WamiChip(
            label: AvailabilityWindow.dayNames[d - 1].substring(0, 3),
            selected: _day == d,
            onTap: () => setState(() => _day = d),
          ),
      ]),
      CounterStepper(label: 'Début (h)', value: _start, min: 6, max: 20, onChanged: (v) => setState(() => _start = v)),
      CounterStepper(label: 'Fin (h)', value: _end, min: 7, max: 21, onChanged: (v) => setState(() => _end = v)),
      WamiPrimaryButton(
        label: 'Ajouter',
        onPressed: _start < _end
            ? () => Navigator.pop(context, AvailabilityWindow(weekday: _day, startHour: _start, endHour: _end))
            : null,
      ),
    ]);
  }
}
