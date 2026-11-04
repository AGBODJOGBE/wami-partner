import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/biz_accent.dart';
import '../../../../shared/data_state.dart';
import '../../domain/entities/lodging.dart';
import '../../domain/usecases/lodging_usecases.dart';
import '../cubit/lodging_cubits.dart';

/// Onglet « Offre » d'un hôtel : prix à la nuit et chambres ouvertes à WAMI.
class RoomTypesPage extends StatelessWidget {
  const RoomTypesPage({super.key, required this.establishmentId});
  final String establishmentId;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RoomTypesCubit>();
    final t = Theme.of(context).textTheme;
    return BlocConsumer<RoomTypesCubit, DataState<List<RoomType>>>(
      listenWhen: (a, b) => b.failure != null && a.failure != b.failure,
      listener: (context, s) => showWamiMessage(context, s.failure!.message),
      builder: (context, s) {
        final types = s.data;
        return WamiScreen(
          showBack: false,
          title: 'Chambres',
          subtitle: 'Prix et disponibilités',
          glow: BizAccent.glow,
          body: types == null
              ? (s.status == LoadStatus.failure
                  ? WamiErrorView(failure: s.failure!, onRetry: () => cubit.load(establishmentId))
                  : const SizedBox(height: 300, child: WamiLoading()))
              : Gap(children: [
                  for (final rt in types)
                    GlassCard(
                      onTap: () => _edit(context, cubit, rt),
                      child: Row(children: [
                        IconBadge(Icons.bed_rounded, color: BizAccent.glow),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(rt.name, style: t.titleSmall),
                            Text('${rt.openUnits} sur ${rt.units} ouvertes · ${rt.capacity} pers.', style: t.bodySmall),
                          ]),
                        ),
                        NumberText(Fmt.fcfa(rt.nightlyPrice), size: 14),
                      ]),
                    ),
                  Text('Photos, équipements et nouveaux types : à valider (back-office web ?).', style: t.bodySmall),
                ]),
        );
      },
    );
  }

  Future<void> _edit(BuildContext context, RoomTypesCubit cubit, RoomType rt) async {
    final edited = await showBizSheet<RoomType>(context, children: (sheet) => [_RoomTypeEditor(type: rt)]);
    if (edited != null && edited != rt) await cubit.save(edited);
  }
}

class _RoomTypeEditor extends StatefulWidget {
  const _RoomTypeEditor({required this.type});
  final RoomType type;

  @override
  State<_RoomTypeEditor> createState() => _RoomTypeEditorState();
}

class _RoomTypeEditorState extends State<_RoomTypeEditor> {
  late int _price = widget.type.nightlyPrice;
  late int _open = widget.type.openUnits;
  static const _step = 500;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Gap(children: [
      Text(widget.type.name, style: t.titleMedium),
      const SectionLabel('Prix à la nuit'),
      Row(children: [
        WamiIconButton(
          icon: Icons.remove_rounded,
          tooltip: 'Baisser',
          onPressed: _price - _step >= UpdateRoomType.minPrice ? () => setState(() => _price -= _step) : null,
        ),
        Expanded(child: Center(child: NumberText(Fmt.fcfa(_price), size: 20))),
        WamiIconButton(icon: Icons.add_rounded, tooltip: 'Augmenter', onPressed: () => setState(() => _price += _step)),
      ]),
      CounterStepper(
        label: 'Chambres ouvertes sur WAMI',
        value: _open,
        min: 0,
        max: widget.type.units,
        onChanged: (v) => setState(() => _open = v),
      ),
      WamiPrimaryButton(
        label: 'Enregistrer',
        onPressed: () => Navigator.pop(context, widget.type.copyWith(nightlyPrice: _price, openUnits: _open)),
      ),
    ]);
  }
}
