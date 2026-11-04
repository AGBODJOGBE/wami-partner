import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wami_core/wami_core.dart';

import '../../features/account/presentation/cubit/account_cubit.dart';
import '../../features/account/presentation/pages/account_page.dart';
import '../../features/earnings/presentation/cubit/earnings_cubits.dart';
import '../../features/earnings/presentation/pages/earnings_pages.dart';
import '../../features/missions/presentation/pages/active_mission_page.dart';
import '../../features/missions/presentation/pages/handover_and_summary_pages.dart';
import '../../features/missions/presentation/pages/missions_home_page.dart';
import '../../features/onboarding/domain/entities/partner.dart';
import '../../features/onboarding/presentation/cubit/onboarding_cubit.dart';
import '../../features/onboarding/presentation/pages/onboarding_pages.dart';
import '../../shared/routes.dart';
import '../session/session_cubit.dart';

/// Navigation de WAMI Pro.
///
/// - Tant que le compte n'est pas actif, seules les pages d'inscription sont accessibles.
/// - Le parcours d'inscription partage un `OnboardingCubit` fourni par son ShellRoute.
/// - La mission en cours s'affiche en plein écran, au-dessus des onglets.
class AppRouter {
  AppRouter(this._session) {
    WamiScreen.homeRoute = ProRoutes.missions;
  }

  final SessionCubit _session;
  final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  static const _splash = '/splash';

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
            path: ProRoutes.welcome,
            builder: (_, __) => const WelcomePage(),
            routes: [
              GoRoute(path: 'code', builder: (_, __) => OtpPage(onRegistered: _session.markOnboarding)),
              GoRoute(
                path: 'documents',
                builder: (_, __) => const DocumentsPage(),
                routes: [
                  GoRoute(path: 'capture', builder: (_, s) => CapturePage(type: s.extra! as DocumentType)),
                ],
              ),
              GoRoute(path: 'status', builder: (_, __) => VerificationPage(onActivated: _session.markActive)),
            ],
          ),
        ],
      ),

      // ── Onglets ──
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => WamiNavShell(
          navigationShell: shell,
          tabs: const [
            (Icons.radar_rounded, 'Missions'),
            (Icons.bar_chart_rounded, 'Gains'),
            (Icons.person_rounded, 'Compte'),
          ],
        ),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: ProRoutes.missions, builder: (_, __) => const MissionsHomePage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: ProRoutes.earnings,
              builder: (_, __) => BlocProvider(create: (_) => sl<EarningsCubit>()..load(), child: const EarningsPage()),
              routes: [
                GoRoute(
                  path: 'wallet',
                  parentNavigatorKey: _rootKey,
                  builder: (_, __) => BlocProvider(
                    create: (_) => sl<PartnerWalletCubit>()..load(),
                    child: const PartnerWalletPage(),
                  ),
                ),
                GoRoute(
                  path: 'performance',
                  parentNavigatorKey: _rootKey,
                  builder: (_, __) => BlocProvider(
                    create: (_) => sl<PerformanceCubit>()..load(),
                    child: const PerformancePage(),
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: ProRoutes.account,
              builder: (_, __) => BlocProvider(
                create: (_) => sl<AccountCubit>()..load(),
                child: AccountPage(onLogout: _session.logout),
              ),
            ),
          ]),
        ],
      ),

      // ── Mission en cours (plein écran) ──
      GoRoute(
        path: ProRoutes.mission,
        builder: (_, __) => const ActiveMissionPage(),
        routes: [
          GoRoute(path: 'handover', builder: (_, __) => const HandoverPage()),
          GoRoute(path: 'summary', builder: (_, __) => const MissionSummaryPage()),
        ],
      ),
    ],
  );

  String? _redirect(BuildContext context, GoRouterState state) {
    final loc = state.matchedLocation;
    final inOnboarding = loc.startsWith(ProRoutes.welcome);
    switch (_session.state.phase) {
      case SessionPhase.unknown:
        return loc == _splash ? null : _splash;
      case SessionPhase.signedOut:
        return (loc == ProRoutes.welcome || loc == ProRoutes.code) ? null : ProRoutes.welcome;
      case SessionPhase.onboarding:
        return inOnboarding && loc != ProRoutes.welcome ? null : ProRoutes.documents;
      case SessionPhase.review:
        return inOnboarding && loc != ProRoutes.welcome ? null : ProRoutes.status;
      case SessionPhase.active:
        return (inOnboarding || loc == _splash) ? ProRoutes.missions : null;
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
