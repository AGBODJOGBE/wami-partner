import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/biz_accent.dart';
import '../../../../shared/data_state.dart';
import '../../domain/entities/order.dart';
import '../cubit/restaurant_cubits.dart';

/// Onglet « Offre » d'un restaurant : pause des commandes et disponibilité des plats.
class MenuPage extends StatelessWidget {
  const MenuPage({super.key, required this.establishmentId});
  final String establishmentId;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MenuCubit>();
    final t = Theme.of(context).textTheme;
    return BlocConsumer<MenuCubit, DataState<RestaurantMenu>>(
      listenWhen: (a, b) => b.failure != null && a.failure != b.failure,
      listener: (context, s) => showWamiMessage(context, s.failure!.message),
      builder: (context, s) {
        final menu = s.data;
        return WamiScreen(
          showBack: false,
          title: 'Menu',
          subtitle: menu?.hours,
          glow: BizAccent.glow,
          body: menu == null
              ? (s.status == LoadStatus.failure
                  ? WamiErrorView(failure: s.failure!, onRetry: () => cubit.load(establishmentId))
                  : const SizedBox(height: 300, child: WamiLoading()))
              : Gap(
                  children: [
                    GlassCard(
                      borderColor: menu.paused ? WamiColors.orangeLight : null,
                      child: ToggleRow(
                        title: 'Pause des commandes',
                        subtitle: menu.paused ? 'Les clients voient « momentanément indisponible »' : 'Pour souffler pendant un rush',
                        value: menu.paused,
                        onChanged: cubit.setPaused,
                      ),
                    ),
                    for (final c in menu.categories) ...[
                      SectionLabel(c),
                      GlassGroup(children: [
                        for (final i in menu.items.where((i) => i.category == c))
                          ListRow(
                            title: i.name,
                            subtitle: i.available ? Fmt.fcfa(i.price) : 'Épuisé · masqué aux clients',
                            trailing: Switch(value: i.available, onChanged: (v) => cubit.setAvailable(i, v)),
                          ),
                      ]),
                    ],
                    Text('Ajout de plats et photos : à valider (back-office web ou dans l’app ?).', style: t.bodySmall),
                  ],
                ),
        );
      },
    );
  }
}
