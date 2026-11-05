import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/dialogs.dart';
import '../../../../shared/places.dart';
import '../../../../shared/pro_accent.dart';
import '../../domain/entities/intercity.dart';
import '../cubit/intercity_cubit.dart';

GeoPoint _geo(Place p) => GeoPoint(label: p.name, city: p.city, lat: p.lat, lng: p.lng);

void _feedback(BuildContext context, IntercityState s) => showWamiMessage(context, s.failure?.message ?? s.notice!);
bool _news(IntercityState a, IntercityState b) => (b.failure != null && a.failure != b.failure) || (b.notice != null && a.notice != b.notice);

String _two(int n) => n.toString().padLeft(2, '0');
String _when(DateTime d) => '${_two(d.day)}/${_two(d.month)} à ${_two(d.hour)} h ${_two(d.minute)}';

const _dayNames = {
  'MONDAY': 'Lun', 'TUESDAY': 'Mar', 'WEDNESDAY': 'Mer', 'THURSDAY': 'Jeu', 'FRIDAY': 'Ven', 'SATURDAY': 'Sam', 'SUNDAY': 'Dim',
};

enum _Tab { offers, routes }

/// Trajets interurbains et trajets quotidiens. Le serveur ne relistant pas ces trajets,
/// l'écran affiche ceux créés depuis cet appareil.
class IntercityPage extends StatefulWidget {
  const IntercityPage({super.key, required this.onNewOffer, required this.onNewRoute});
  final VoidCallback onNewOffer;
  final VoidCallback onNewRoute;

  @override
  State<IntercityPage> createState() => _IntercityPageState();
}

class _IntercityPageState extends State<IntercityPage> {
  _Tab _tab = _Tab.offers;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return BlocConsumer<IntercityCubit, IntercityState>(
      listenWhen: _news,
      listener: _feedback,
      builder: (context, s) {
        final cubit = context.read<IntercityCubit>();
        return WamiScreen(
          title: 'Trajets programmés',
          glow: ProAccent.glow,
          body: Gap(
            children: [
              WamiSegmented<_Tab>(
                options: const [(_Tab.offers, 'Interurbains'), (_Tab.routes, 'Quotidiens')],
                value: _tab,
                onChanged: (v) => setState(() => _tab = v),
              ),
              if (_tab == _Tab.offers) ...[
                if (s.offers.isEmpty) Text('Aucun trajet publié depuis cet appareil.', style: t.bodySmall),
                for (final o in s.offers)
                  GlassCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      ListRow(
                        title: '${o.origin} → ${o.destination}',
                        subtitle: '${_when(o.departure)} · ${o.seats} places · ${Fmt.fcfa(o.pricePerSeat)}/place',
                        icon: Icons.alt_route_rounded,
                        trailing: WamiTag(o.statusLabel),
                      ),
                      Wrap(spacing: 4, children: [
                        if (o.canStart) TextButton(onPressed: s.busy ? null : () => cubit.start(o.id), child: const Text('Démarrer')),
                        if (o.canComplete) TextButton(onPressed: s.busy ? null : () => cubit.complete(o.id), child: const Text('Terminer')),
                        if (o.canCancel)
                          TextButton(
                            onPressed: s.busy
                                ? null
                                : () async {
                                    final r = await askReason(context, title: 'Annuler ce trajet ?', hint: 'Motif (5 caractères au moins)', confirmLabel: 'Annuler le trajet', required: true);
                                    if (r != null) cubit.cancel(o.id, r);
                                  },
                            child: const Text('Annuler'),
                          ),
                      ]),
                    ]),
                  ),
                Text('Le départ exige au moins un passager confirmé. Un seul trajet actif à la fois.', style: t.bodySmall?.copyWith(fontSize: 11.5)),
              ] else ...[
                if (s.routes.isEmpty) Text('Aucun trajet quotidien créé depuis cet appareil.', style: t.bodySmall),
                for (final r in s.routes)
                  GlassCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      ListRow(
                        title: '${r.pickup} → ${r.dropoff}',
                        subtitle: '${r.days.map((d) => _dayNames[d] ?? d).join(' ')} · ${r.time} · ${Fmt.fcfa(r.pricePerRide)}',
                        icon: Icons.repeat_rounded,
                        trailing: WamiTag(r.statusLabel),
                      ),
                      Wrap(spacing: 4, children: [
                        if (r.status == 'ACTIVE')
                          TextButton(
                            onPressed: s.busy
                                ? null
                                : () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      firstDate: DateTime.now().add(const Duration(days: 1)),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                      helpText: 'Reprise (facultatif : annuler pour une pause sans date)',
                                    );
                                    cubit.pauseRoute(r.id, date);
                                  },
                            child: const Text('Mettre en pause'),
                          ),
                        if (r.status == 'PAUSED') TextButton(onPressed: s.busy ? null : () => cubit.resumeRoute(r.id), child: const Text('Reprendre')),
                        if (r.status == 'ACTIVE' || r.status == 'PAUSED')
                          TextButton(
                            onPressed: s.busy
                                ? null
                                : () async {
                                    final reason = await askReason(context, title: 'Annuler ce trajet ?', hint: 'Motif (5 caractères au moins)', confirmLabel: 'Annuler', required: true);
                                    if (reason != null) cubit.cancelRoute(r.id, reason);
                                  },
                            child: const Text('Annuler'),
                          ),
                      ]),
                    ]),
                  ),
              ],
            ],
          ),
          bottom: WamiPrimaryButton(
            label: _tab == _Tab.offers ? 'Publier un trajet' : 'Nouveau trajet quotidien',
            icon: Icons.add_rounded,
            loading: s.busy,
            onPressed: _tab == _Tab.offers ? widget.onNewOffer : widget.onNewRoute,
          ),
        );
      },
    );
  }
}

// ─── Publier un trajet interurbain ───────────────────────────────────────────

class PublishOfferPage extends StatefulWidget {
  const PublishOfferPage({super.key});

  @override
  State<PublishOfferPage> createState() => _PublishOfferPageState();
}

class _PublishOfferPageState extends State<PublishOfferPage> {
  Place? _from;
  Place? _to;
  DateTime? _departure;
  int _seats = 3;
  final _price = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _price.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDeparture() async {
    final now = DateTime.now();
    final date = await showDatePicker(context: context, firstDate: now, lastDate: now.add(const Duration(days: 90)), initialDate: now);
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 8, minute: 0));
    if (time == null) return;
    setState(() => _departure = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<IntercityCubit, IntercityState>(
      listenWhen: _news,
      listener: _feedback,
      builder: (context, s) {
        return WamiScreen(
          title: 'Publier un trajet',
          glow: ProAccent.glow,
          body: Gap(
            children: [
              const SectionLabel('De'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final p in Places.cities) WamiChip(label: p.name, selected: _from == p, onTap: () => setState(() => _from = p)),
              ]),
              const SectionLabel('Vers'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final p in Places.cities) WamiChip(label: p.name, selected: _to == p, onTap: () => setState(() => _to = p)),
              ]),
              GlassGroup(children: [
                ListRow(
                  title: _departure == null ? 'Date et heure de départ' : _when(_departure!),
                  icon: Icons.event_rounded,
                  onTap: _pickDeparture,
                ),
              ]),
              Row(children: [
                Expanded(child: Text('Places : $_seats', style: Theme.of(context).textTheme.titleSmall)),
                IconButton(onPressed: _seats > 1 ? () => setState(() => _seats--) : null, icon: const Icon(Icons.remove_circle_outline)),
                IconButton(onPressed: _seats < 6 ? () => setState(() => _seats++) : null, icon: const Icon(Icons.add_circle_outline)),
              ]),
              WamiTextField(hint: 'Prix par place (FCFA)', controller: _price, keyboardType: TextInputType.number),
              WamiTextField(hint: 'Remarque (facultatif)', controller: _note),
            ],
          ),
          bottom: WamiPrimaryButton(
            label: 'Publier',
            loading: s.busy,
            onPressed: _from == null || _to == null || _departure == null
                ? null
                : () async {
                    final ok = await context.read<IntercityCubit>().publish(OfferDraft(
                          origin: _geo(_from!),
                          destination: _geo(_to!),
                          departure: _departure!,
                          seats: _seats,
                          pricePerSeat: int.tryParse(_price.text.trim()) ?? 0,
                          description: _note.text,
                        ));
                    if (ok && context.mounted) context.pop();
                  },
          ),
        );
      },
    );
  }
}

// ─── Nouveau trajet quotidien ────────────────────────────────────────────────

class NewRoutePage extends StatefulWidget {
  const NewRoutePage({super.key});

  @override
  State<NewRoutePage> createState() => _NewRoutePageState();
}

class _NewRoutePageState extends State<NewRoutePage> {
  final _passenger = TextEditingController();
  final _price = TextEditingController();
  final _days = <String>{};
  Place? _from;
  Place? _to;
  TimeOfDay _time = const TimeOfDay(hour: 7, minute: 30);
  DateTime _start = DateTime.now().add(const Duration(days: 1));
  bool _cash = true;

  @override
  void dispose() {
    _passenger.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final places = [...Places.quarters, ...Places.cities.where((c) => !Places.quarters.any((q) => q.name == c.name))];
    return BlocConsumer<IntercityCubit, IntercityState>(
      listenWhen: _news,
      listener: _feedback,
      builder: (context, s) {
        return WamiScreen(
          title: 'Trajet quotidien',
          glow: ProAccent.glow,
          body: Gap(
            children: [
              WamiTextField(hint: 'Identifiant du passager', controller: _passenger),
              Text('Fourni par le passager depuis son application.', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11.5)),
              const SectionLabel('Prise en charge'),
              Wrap(spacing: 8, runSpacing: 8, children: [for (final p in places) WamiChip(label: p.name, selected: _from == p, onTap: () => setState(() => _from = p))]),
              const SectionLabel('Destination'),
              Wrap(spacing: 8, runSpacing: 8, children: [for (final p in places) WamiChip(label: p.name, selected: _to == p, onTap: () => setState(() => _to = p))]),
              const SectionLabel('Jours'),
              Wrap(spacing: 8, children: [
                for (final e in _dayNames.entries)
                  WamiChip(label: e.value, selected: _days.contains(e.key), onTap: () => setState(() => _days.contains(e.key) ? _days.remove(e.key) : _days.add(e.key))),
              ]),
              GlassGroup(children: [
                ListRow(
                  title: 'Heure : ${_two(_time.hour)}:${_two(_time.minute)}',
                  icon: Icons.schedule_rounded,
                  onTap: () async {
                    final t = await showTimePicker(context: context, initialTime: _time);
                    if (t != null) setState(() => _time = t);
                  },
                ),
                ListRow(
                  title: 'Début : ${_two(_start.day)}/${_two(_start.month)}/${_start.year}',
                  icon: Icons.event_rounded,
                  onTap: () async {
                    final d = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)), initialDate: _start);
                    if (d != null) setState(() => _start = d);
                  },
                ),
              ]),
              WamiTextField(hint: 'Prix par trajet (FCFA)', controller: _price, keyboardType: TextInputType.number),
              WamiSegmented<bool>(options: const [(true, 'Espèces'), (false, 'Portefeuille')], value: _cash, onChanged: (v) => setState(() => _cash = v)),
            ],
          ),
          bottom: WamiPrimaryButton(
            label: 'Créer',
            loading: s.busy,
            onPressed: _from == null || _to == null
                ? null
                : () async {
                    final ok = await context.read<IntercityCubit>().createRoute(RouteDraft(
                          passengerId: _passenger.text,
                          pickup: _geo(_from!),
                          dropoff: _geo(_to!),
                          days: _dayNames.keys.where(_days.contains).toList(),
                          time: '${_two(_time.hour)}:${_two(_time.minute)}',
                          startDate: _start,
                          pricePerRide: int.tryParse(_price.text.trim()) ?? 0,
                          cash: _cash,
                        ));
                    if (ok && context.mounted) context.pop();
                  },
          ),
        );
      },
    );
  }
}
