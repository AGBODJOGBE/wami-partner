import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../features/establishments/domain/entities/establishment.dart';
import '../../features/establishments/presentation/cubit/establishment_cubit.dart';
import '../../features/finances/presentation/cubit/finances_cubit.dart';
import '../../features/finances/presentation/pages/finances_pages.dart';
import '../../features/lodging/presentation/cubit/lodging_cubits.dart';
import '../../features/lodging/presentation/pages/planning_page.dart';
import '../../features/lodging/presentation/pages/room_types_page.dart';
import '../../features/rental/presentation/cubit/rental_cubits.dart';
import '../../features/rental/presentation/pages/rental_pages.dart';
import '../../features/restaurant/presentation/cubit/restaurant_cubits.dart';
import '../../features/restaurant/presentation/pages/menu_page.dart';
import '../../features/restaurant/presentation/pages/orders_board_page.dart';
import '../../features/transport/presentation/cubit/transport_cubits.dart';
import '../../features/transport/presentation/pages/departures_page.dart';
import '../../features/transport/presentation/pages/lines_page.dart';
import '../../shared/business_activity.dart';

/// Construit un onglet pour l'établissement courant.
///
/// Changer d'établissement change la clé : les cubits de l'onglet sont recréés
/// et rechargent les données du nouvel établissement.
class EstablishmentScope extends StatelessWidget {
  const EstablishmentScope({super.key, required this.builder});
  final Widget Function(BuildContext context, Establishment establishment) builder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EstablishmentCubit, EstablishmentState>(
      buildWhen: (a, b) => a.status != b.status || a.current?.id != b.current?.id,
      builder: (context, s) {
        final e = s.current;
        if (e != null) return KeyedSubtree(key: ValueKey(e.id), child: builder(context, e));
        return Scaffold(
          body: switch (s.status) {
            LoadStatus.failure => WamiErrorView(failure: s.failure!, onRetry: context.read<EstablishmentCubit>().load),
            LoadStatus.ready => const EmptyState(icon: Icons.storefront_rounded, message: 'Aucun établissement sur ce compte.'),
            _ => const WamiLoading(),
          },
        );
      },
    );
  }
}

/// Onglet « Activité » : l'écran dépend du métier de l'établissement.
Widget buildActivityTab(Establishment e) => switch (e.activity.family) {
      ActivityFamily.food => BlocProvider(create: (_) => sl<OrdersCubit>()..watch(e.id), child: const OrdersBoardPage()),
      ActivityFamily.lodging => BlocProvider(create: (_) => sl<PlanningCubit>()..load(e.id), child: const PlanningPage()),
      ActivityFamily.rental => BlocProvider(create: (_) => sl<VisitsCubit>()..load(e.id), child: const VisitsPage()),
      ActivityFamily.transport => BlocProvider(create: (_) => sl<DeparturesCubit>()..load(e.id), child: const DeparturesPage()),
    };

/// Onglet « Offre » : menu, chambres, biens ou lignes.
Widget buildOfferTab(Establishment e) => switch (e.activity.family) {
      ActivityFamily.food => BlocProvider(create: (_) => sl<MenuCubit>()..load(e.id), child: MenuPage(establishmentId: e.id)),
      ActivityFamily.lodging => BlocProvider(create: (_) => sl<RoomTypesCubit>()..load(e.id), child: RoomTypesPage(establishmentId: e.id)),
      ActivityFamily.rental => BlocProvider(create: (_) => sl<ListingsCubit>()..load(e.id), child: ListingsPage(establishmentId: e.id)),
      ActivityFamily.transport => BlocProvider(create: (_) => sl<LinesCubit>()..load(e.id), child: LinesPage(establishmentId: e.id)),
    };

Widget buildFinancesTab(Establishment e) =>
    BlocProvider(create: (_) => sl<FinancesCubit>()..load(e.id), child: FinancesPage(establishmentId: e.id));

IconData activityIcon(ActivityFamily? f) => switch (f) {
      ActivityFamily.food => Icons.receipt_long_rounded,
      ActivityFamily.lodging => Icons.calendar_month_rounded,
      ActivityFamily.rental => Icons.event_available_rounded,
      ActivityFamily.transport => Icons.directions_bus_rounded,
      null => Icons.inbox_rounded,
    };
