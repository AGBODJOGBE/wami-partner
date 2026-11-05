import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import 'app/router/app_router.dart';
import 'shared/app_version.dart';
import 'shared/contact.dart';
import 'shared/push_service.dart';
import 'app/session/session_cubit.dart';
import 'features/missions/presentation/bloc/missions_bloc.dart';

/// Racine de WAMI Pro.
///
/// Blocs globaux : la session (inscrit, en vérification, actif) et les missions
/// (le statut en ligne et la mission en cours survivent aux changements d'onglet).
class WamiProApp extends StatefulWidget {
  const WamiProApp({super.key});

  @override
  State<WamiProApp> createState() => _WamiProAppState();
}

class _WamiProAppState extends State<WamiProApp> {
  late final SessionCubit _session = sl<SessionCubit>()..load();
  late final AppRouter _router = AppRouter(_session);

  @override
  void initState() {
    super.initState();
    // Un 401 sur une session ouverte (jeton expiré, autre appareil) ramène à la connexion.
    sl<AuthInterceptor>().onSessionExpired = _session.expire;
  }

  /// Mise à jour proposée, ou imposée quand le serveur l'exige (écran non fermable).
  Future<void> _checkVersion() async {
    final v = await sl<AppVersionService>().check();
    final ctx = _router.config.routerDelegate.navigatorKey.currentContext;
    if (v == null || !v.updateAvailable || ctx == null || !ctx.mounted) return;
    await showDialog<void>(
      context: ctx,
      barrierDismissible: !v.forceUpdate,
      builder: (context) => PopScope(
        canPop: !v.forceUpdate,
        child: AlertDialog(
          title: Text(v.forceUpdate ? 'Mise à jour obligatoire' : 'Nouvelle version disponible'),
          content: Text('Version ${v.latest}${v.notes.isEmpty ? '' : '\n\n${v.notes}'}'),
          actions: [
            if (!v.forceUpdate) TextButton(onPressed: () => Navigator.pop(context), child: const Text('Plus tard')),
            FilledButton(
              onPressed: () => Contact.openUrl(context, v.url),
              child: const Text('Mettre à jour'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _session.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _session),
        BlocProvider(create: (_) => sl<MissionsBloc>()),
      ],
      // Les missions ne démarrent qu'une fois le compte actif, et s'arrêtent à la déconnexion.
      child: BlocListener<SessionCubit, SessionState>(
        listenWhen: (a, b) => a.phase != b.phase,
        listener: (context, s) {
          final missions = context.read<MissionsBloc>();
          if (s.phase == SessionPhase.active) {
            missions.add(const MissionsStarted());
            if (!sl<AppConfig>().useFakeBackend) {
              sl<PushService>().register();
              _checkVersion();
            }
          }
          if (s.phase == SessionPhase.signedOut) missions.add(const MissionsReset());
        },
        child: MaterialApp.router(
          title: 'WAMI Pro',
          debugShowCheckedModeBanner: false,
          theme: WamiTheme.dark(),
          routerConfig: _router.config,
        ),
      ),
    );
  }
}
