import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import 'app/router/app_router.dart';
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
  void dispose() {
    _session.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _session),
        BlocProvider(create: (_) => sl<MissionsBloc>()..add(const MissionsStarted())),
      ],
      child: MaterialApp.router(
        title: 'WAMI Pro',
        debugShowCheckedModeBanner: false,
        theme: WamiTheme.dark(),
        routerConfig: _router.config,
      ),
    );
  }
}
