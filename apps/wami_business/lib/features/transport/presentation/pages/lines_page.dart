import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/biz_accent.dart';
import '../../../../shared/data_state.dart';
import '../../domain/entities/transport.dart';
import '../cubit/transport_cubits.dart';

/// Onglet « Offre » d'une compagnie : lignes et prix.
class LinesPage extends StatelessWidget {
  const LinesPage({super.key, required this.establishmentId});
  final String establishmentId;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LinesCubit>();
    final t = Theme.of(context).textTheme;
    return BlocConsumer<LinesCubit, DataState<List<BusLine>>>(
      listenWhen: (a, b) => b.failure != null && a.failure != b.failure,
      listener: (context, s) => showWamiMessage(context, s.failure!.message),
      builder: (context, s) {
        final lines = s.data;
        return WamiScreen(
          showBack: false,
          title: 'Lignes',
          glow: BizAccent.glow,
          body: lines == null
              ? (s.status == LoadStatus.failure
                  ? WamiErrorView(failure: s.failure!, onRetry: () => cubit.load(establishmentId))
                  : const SizedBox(height: 300, child: WamiLoading()))
              : Gap(children: [
                  for (final l in lines)
                    GlassCard(
                      onTap: () => _editPrice(context, cubit, l),
                      child: Row(children: [
                        const ServiceIllustration(ServiceArt.bus, size: 44),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(l.label, style: t.titleSmall),
                            Text('${Fmt.duration(l.durationMinutes)} · ${l.departuresPerDay} départ${l.departuresPerDay > 1 ? 's' : ''}/jour',
                                style: t.bodySmall),
                          ]),
                        ),
                        NumberText(Fmt.fcfa(l.price), size: 14),
                      ]),
                    ),
                  Text('Création de lignes et d’horaires : à valider (back-office web ?).', style: t.bodySmall),
                ]),
        );
      },
    );
  }

  Future<void> _editPrice(BuildContext context, LinesCubit cubit, BusLine l) async {
    var price = l.price;
    final saved = await showBizSheet<int>(context, children: (sheet) => [
          StatefulBuilder(
            builder: (context, setState) => Gap(children: [
              Text(l.label, style: Theme.of(context).textTheme.titleMedium),
              Row(children: [
                WamiIconButton(icon: Icons.remove_rounded, tooltip: 'Baisser', onPressed: () => setState(() => price -= 500)),
                Expanded(child: Center(child: NumberText(Fmt.fcfa(price), size: 20))),
                WamiIconButton(icon: Icons.add_rounded, tooltip: 'Augmenter', onPressed: () => setState(() => price += 500)),
              ]),
              Text('Les billets déjà vendus gardent leur prix.', style: Theme.of(context).textTheme.bodySmall),
              WamiPrimaryButton(label: 'Enregistrer', onPressed: () => Navigator.pop(sheet, price)),
            ]),
          ),
        ]);
    if (saved != null && saved != l.price) await cubit.updatePrice(l, saved);
  }
}
