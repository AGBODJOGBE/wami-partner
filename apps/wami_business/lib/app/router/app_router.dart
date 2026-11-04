import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wami_core/wami_core.dart';

import '../../features/account/presentation/cubit/account_cubit.dart';
import '../../features/account/presentation/pages/account_pages.dart';
import '../../features/establishments/domain/entities/establishment.dart';
import '../../features/establishments/presentation/cubit/establishment_cubit.dart';
import '../../features/establishments/presentation/pages/dashboard_page.dart';
import '../../features/finances/domain/entities/finances.dart';
import '../../features/finances/presentation/pages/finances_pages.dart';
import '../../features/lodging/presentation/cubit/lodging_cubits.dart';
import '../../features/lodging/presentation/pages/front_desk_pages.dart';
import '../../features/onboarding/presentation/cubit/onboarding_cubit.dart';
import '../../features/onboarding/presentation/pages/onboarding_pages.dart';
import '../../features/reviews/presentation/cubit/reviews_cubit.dart';
import '../../features/reviews/presentation/pages/reviews_page.dart';
import '../../features/transport/presentation/cubit/transport_cubits.dart';
import '../../features/transport/presentation/pages/seat_pages.dart';
import '../../shared/routes.dart';
import '../session/session_cubit.dart';
import 'establishment_scope.dart';

/// Navigation de WAMI Business.
///
/// - Inscription puis vérification tant que le compte n'est pas actif.
/// - Cinq onglets ; « Activité » et « Offre » changent selon le métier de l'établissement courant.
/// - Les pages d'action (check-in, plan des places…) s'ouvrent en plein écran, au-dessus des onglets.
class AppRouter {
  AppRouter(this._session) {
    WamiScreen.homeRoute = BizRoutes.dashboard;
  }

  final SessionCubit _session;
  final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  static const _splash = '/splash';

  /// Établissement courant, lu par les pages plein écran.
  static String _currentId(BuildContext context) => context.read<EstablishmentCubit>().state.current?.id ?? '';

  late final GoRouter config = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: _splash,
    refreshListenable: _StreamListenable(_session.stream),
    redirect: _redirect,
    routes: [
      GoRoute(path: _splash, builder: (_, __) => const Scaffold(body: WamiLoading())),

      // ── Inscription ──
      ShellRoute(
        builder: (_, __, child) => BlocProvider(create: (_) => sl<OnboardingCubit>(), child: child),
        routes: [
          GoRoute(
            path: BizRoutes.welcome,
            builder: (_, __) => const WelcomePage(),
            routes: [
              GoRoute(path: 'code', builder: (_, __) => OtpPage(onRegistered: _session.markOnboarding)),
              GoRoute(path: 'verification', builder: (_, __) => VerificationPage(onActivated: _session.markActive)),
            ],
          ),
        ],
      ),

      // ── Onglets ──
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => BlocBuilder<EstablishmentCubit, EstablishmentState>(
          buildWhen: (a, b) => a.current?.activity != b.current?.activity,
          builder: (context, s) {
            final family = s.current?.activity.family;
            return WamiNavShell(
              navigationShell: shell,
              tabs: [
                (Icons.space_dashboard_rounded, 'Tableau'),
                (activityIcon(family), family?.activityTab ?? 'Activité'),
                (Icons.storefront_rounded, family?.offerTab ?? 'Offre'),
                (Icons.account_balance_wallet_rounded, 'Finances'),
                (Icons.person_rounded, 'Compte'),
              ],
            );
          },
        ),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: BizRoutes.dashboard,
              builder: (_, __) => EstablishmentScope(
                builder: (context, e) => BlocProvider(
                  create: (_) => sl<DashboardCubit>()..load(e.id),
                  child: DashboardPage(establishmentId: e.id, onOpen: (target) => _openInbox(context, target)),
                ),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: BizRoutes.activity,
              builder: (_, __) => EstablishmentScope(builder: (_, e) => buildActivityTab(e)),
              routes: [
                GoRoute(
                  path: 'desk-booking',
                  parentNavigatorKey: _rootKey,
                  builder: (context, _) => BlocProvider(
                    create: (_) => sl<DeskBookingCubit>()..load(_currentId(context)),
                    child: const DeskBookingPage(),
                  ),
                ),
                GoRoute(
                  path: 'check-in',
                  parentNavigatorKey: _rootKey,
                  builder: (context, _) => BlocProvider(
                    create: (_) => sl<CheckInCubit>(),
                    child: CheckInPage(establishmentId: _currentId(context)),
                  ),
                ),
                GoRoute(
                  path: 'seats',
                  parentNavigatorKey: _rootKey,
                  builder: (_, s) => BlocProvider(
                    create: (_) => sl<SeatMapCubit>()..load(s.extra! as String),
                    child: const SeatMapPage(),
                  ),
                ),
                GoRoute(
                  path: 'boarding',
                  parentNavigatorKey: _rootKey,
                  builder: (_, s) => BlocProvider(
                    create: (_) => sl<SeatMapCubit>()..load(s.extra! as String),
                    child: const BoardingPage(),
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: BizRoutes.offer, builder: (_, __) => EstablishmentScope(builder: (_, e) => buildOfferTab(e))),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: BizRoutes.finances,
              builder: (_, __) => EstablishmentScope(builder: (_, e) => buildFinancesTab(e)),
              routes: [
                GoRoute(
                  path: 'payout',
                  parentNavigatorKey: _rootKey,
                  builder: (_, s) => PayoutDetailPage(payout: s.extra! as Payout),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: BizRoutes.account,
              builder: (_, __) => BlocProvider(
                create: (_) => sl<AccountCubit>()..load(),
                child: AccountPage(onLogout: _session.logout),
              ),
              routes: [
                GoRoute(
                  path: 'team',
                  parentNavigatorKey: _rootKey,
                  builder: (_, __) => BlocProvider(create: (_) => sl<AccountCubit>()..load(), child: const TeamPage()),
                ),
                GoRoute(
                  path: 'reviews',
                  parentNavigatorKey: _rootKey,
                  builder: (context, _) => BlocProvider(
                    create: (_) => sl<ReviewsCubit>()..load(_currentId(context)),
                    child: ReviewsPage(establishmentId: _currentId(context)),
                  ),
                ),
              ],
            ),
          ]),
        ],
      ),
    ],
  );

  void _openInbox(BuildContext context, InboxTarget target) {
    switch (target) {
      case InboxTarget.activity:
        context.go(BizRoutes.activity);
      case InboxTarget.finances:
        context.go(BizRoutes.finances);
      case InboxTarget.reviews:
        context.push(BizRoutes.reviews);
    }
  }

  String? _redirect(BuildContext context, GoRouterState state) {
    final loc = state.matchedLocation;
    switch (_session.state.phase) {
      case SessionPhase.unknown:
        return loc == _splash ? null : _splash;
      case SessionPhase.signedOut:
        return (loc == BizRoutes.welcome || loc == BizRoutes.code) ? null : BizRoutes.welcome;
      case SessionPhase.onboarding:
        return loc == BizRoutes.verification ? null : BizRoutes.verification;
      case SessionPhase.active:
        return (loc.startsWith(BizRoutes.welcome) || loc == _splash) ? BizRoutes.dashboard : null;
    }
  }
}

/// Relance l'évaluation des redirections à chaque changement de session.
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
