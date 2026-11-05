import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/photo_picker.dart';
import '../../../../shared/pro_accent.dart';
import '../../../../shared/routes.dart';
import '../../domain/entities/vehicle.dart';
import '../cubit/vehicles_cubit.dart';

void _feedback(BuildContext context, VehiclesState s) {
  if (s.failure != null) showWamiMessage(context, s.failure!.message);
  if (s.notice != null) showWamiMessage(context, s.notice!);
}

bool _news(VehiclesState a, VehiclesState b) => (b.failure != null && a.failure != b.failure) || (b.notice != null && a.notice != b.notice);

/// Mes véhicules : activer, choisir les catégories, demander une montée de catégorie, supprimer.
class VehiclesPage extends StatelessWidget {
  const VehiclesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return BlocConsumer<VehiclesCubit, VehiclesState>(
      listenWhen: _news,
      listener: _feedback,
      builder: (context, s) {
        return WamiScreen(
          title: 'Mes véhicules',
          glow: ProAccent.glow,
          body: s.status.isLoading && s.items.isEmpty
              ? const SizedBox(height: 300, child: WamiLoading())
              : Gap(
                  children: [
                    if (s.items.isEmpty) Text('Aucun véhicule enregistré.', style: t.bodySmall),
                    for (final v in s.items)
                      GlassCard(
                        borderColor: v.isActive ? ProAccent.glow.withValues(alpha: 0.6) : null,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          ListRow(
                            title: '${v.title} · ${v.plate}',
                            subtitle: '${v.kind.label} · ${v.color} · ${v.year}',
                            icon: v.kind == VehicleKind.car ? Icons.directions_car_rounded : Icons.two_wheeler_rounded,
                            iconColor: v.isVerified ? WamiColors.success : WamiColors.glowHebergement,
                            trailing: WamiTag(v.isActive ? 'Actif' : v.statusLabel),
                          ),
                          if (v.kind == VehicleKind.car && v.category != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('Catégories actives : ${v.activeCategories.map((c) => c.label).join(', ')}', style: t.bodySmall),
                            ),
                          Wrap(spacing: 4, children: [
                            if (!v.isActive && v.usable)
                              TextButton(onPressed: s.busy ? null : () => context.read<VehiclesCubit>().activate(v.id), child: const Text('Utiliser')),
                            if (v.selectableCategories.isNotEmpty)
                              TextButton(onPressed: s.busy ? null : () => _categories(context, v), child: const Text('Catégories')),
                            if (v.kind == VehicleKind.car && v.category != null)
                              TextButton(onPressed: s.busy ? null : () => _upgrade(context, v), child: const Text('Catégorie supérieure')),
                            if (v.deletable)
                              TextButton(onPressed: s.busy ? null : () => _delete(context, v), child: const Text('Supprimer')),
                          ]),
                        ]),
                      ),
                    Text('5 véhicules au plus. Un véhicule neuf est vérifié par WAMI avant de pouvoir servir.', style: t.bodySmall?.copyWith(fontSize: 11.5)),
                  ],
                ),
          bottom: WamiPrimaryButton(
            label: 'Ajouter un véhicule',
            icon: Icons.add_rounded,
            loading: s.busy,
            onPressed: () => context.push(ProRoutes.addVehicle),
          ),
        );
      },
    );
  }

  Future<void> _categories(BuildContext context, VehicleItem v) async {
    final cubit = context.read<VehiclesCubit>();
    final chosen = {...v.activeCategories};
    final result = await showDialog<List<VehicleCategory>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Catégories de service'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final c in v.selectableCategories)
              CheckboxListTile(
                value: chosen.contains(c),
                title: Text(c.label),
                onChanged: (on) => setState(() => on == true ? chosen.add(c) : chosen.remove(c)),
              ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Retour')),
            FilledButton(onPressed: chosen.isEmpty ? null : () => Navigator.pop(context, chosen.toList()), child: const Text('Enregistrer')),
          ],
        ),
      ),
    );
    if (result != null) cubit.setCategories(v.id, result);
  }

  Future<void> _upgrade(BuildContext context, VehicleItem v) async {
    final cubit = context.read<VehiclesCubit>();
    final reason = TextEditingController();
    VehicleCategory? pick;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Catégorie supérieure'),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, children: [
              for (final c in VehicleCategory.values)
                ChoiceChip(label: Text(c.label), selected: pick == c, onSelected: (_) => setState(() => pick = c)),
            ]),
            TextField(controller: reason, decoration: const InputDecoration(hintText: 'Pourquoi ? (facultatif)')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Retour')),
            FilledButton(onPressed: pick == null ? null : () => Navigator.pop(context, true), child: const Text('Envoyer')),
          ],
        ),
      ),
    );
    if (ok == true && pick != null) cubit.requestUpgrade(v.id, pick!, reason.text);
    reason.dispose();
  }

  Future<void> _delete(BuildContext context, VehicleItem v) async {
    final cubit = context.read<VehiclesCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce véhicule ?'),
        content: Text('${v.title} (${v.plate}) sera retiré de votre compte.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Retour')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok == true) cubit.remove(v.id);
  }
}

// ─── Ajouter un véhicule ─────────────────────────────────────────────────────

class AddVehiclePage extends StatefulWidget {
  const AddVehiclePage({super.key});

  @override
  State<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final _make = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController();
  final _color = TextEditingController();
  final _plate = TextEditingController();
  VehicleKind _kind = VehicleKind.moto;
  int _seats = 1;
  String? _insurance;
  String? _registration;

  @override
  void dispose() {
    for (final c in [_make, _model, _year, _color, _plate]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VehiclesCubit, VehiclesState>(
      listenWhen: _news,
      listener: _feedback,
      builder: (context, s) {
        final (min, max) = _kind.seatRange;
        return WamiScreen(
          title: 'Nouveau véhicule',
          glow: ProAccent.glow,
          body: Gap(
            children: [
              Wrap(spacing: 8, children: [
                for (final k in VehicleKind.values)
                  WamiChip(
                    label: k.label,
                    selected: _kind == k,
                    onTap: () => setState(() {
                      _kind = k;
                      _seats = k.seatRange.$1;
                    }),
                  ),
              ]),
              WamiTextField(hint: 'Marque', controller: _make),
              WamiTextField(hint: 'Modèle', controller: _model),
              WamiTextField(hint: 'Année', controller: _year, keyboardType: TextInputType.number),
              WamiTextField(hint: 'Couleur', controller: _color),
              WamiTextField(hint: 'Plaque d’immatriculation', controller: _plate),
              Row(children: [
                Expanded(child: Text('Places : $_seats', style: Theme.of(context).textTheme.titleSmall)),
                IconButton(onPressed: _seats > min ? () => setState(() => _seats--) : null, icon: const Icon(Icons.remove_circle_outline)),
                IconButton(onPressed: _seats < max ? () => setState(() => _seats++) : null, icon: const Icon(Icons.add_circle_outline)),
              ]),
              GlassGroup(children: [
                ListRow(
                  title: _insurance == null ? 'Photo de l’assurance (obligatoire)' : 'Assurance ajoutée',
                  icon: _insurance == null ? Icons.photo_camera_outlined : Icons.check_circle_rounded,
                  iconColor: _insurance == null ? null : WamiColors.success,
                  onTap: () async {
                    final p = await PhotoPicker.camera();
                    if (p != null) setState(() => _insurance = p);
                  },
                ),
                ListRow(
                  title: _registration == null ? 'Photo de la carte grise (facultatif)' : 'Carte grise ajoutée',
                  icon: _registration == null ? Icons.photo_camera_outlined : Icons.check_circle_rounded,
                  iconColor: _registration == null ? null : WamiColors.success,
                  onTap: () async {
                    final p = await PhotoPicker.camera();
                    if (p != null) setState(() => _registration = p);
                  },
                ),
              ]),
            ],
          ),
          bottom: WamiPrimaryButton(
            label: 'Ajouter',
            loading: s.busy,
            onPressed: _insurance == null
                ? null
                : () async {
                    final ok = await context.read<VehiclesCubit>().add(NewVehicle(
                          kind: _kind,
                          make: _make.text,
                          model: _model.text,
                          year: int.tryParse(_year.text.trim()) ?? 0,
                          color: _color.text,
                          plate: _plate.text,
                          seats: _seats,
                          insurancePath: _insurance!,
                          registrationPath: _registration,
                        ));
                    if (ok && context.mounted) context.pop();
                  },
          ),
        );
      },
    );
  }
}
