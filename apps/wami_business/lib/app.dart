import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import 'app/router/app_router.dart';
import 'app/session/session_cubit.dart';
import 'features/establishments/presentation/cubit/establishment_cubit.dart';

/// Racine de WAMI Business.
///
/// Blocs globaux : la session (inscrit, en vérification, actif) et
/// l'établissement sélectionné (un même compte peut gérer un restaurant
/// et un hôtel : tous les onglets suivent l'établissement courant).
class WamiBusinessApp extends StatefulWidget {
  const WamiBusinessApp({super.key});

  @override
  State<WamiBusinessApp> createState() => _WamiBusinessAppState();
}

class _WamiBusinessAppState extends State<WamiBusinessApp> {
  late final SessionCubit _session = sl<SessionCubit>()..load();
  late final EstablishmentCubit _establishments = sl<EstablishmentCubit>();
  late final AppRouter _router = AppRouter(_session);

  @override
  void dispose() {
    _session.close();
    _establishments.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _session),
        BlocProvider.value(value: _establishments),
      ],
      // Les établissements ne se chargent qu'une fois le compte actif.
      child: BlocListener<SessionCubit, SessionState>(
        listenWhen: (a, b) => a.phase != b.phase,
        listener: (_, s) {
          if (s.phase == SessionPhase.active) _establishments.load();
          if (s.phase == SessionPhase.signedOut) _establishments.clear();
        },
        child: MaterialApp.router(
          title: 'WAMI Business',
          debugShowCheckedModeBanner: false,
          theme: WamiTheme.dark(),
          routerConfig: _router.config,
        ),
      ),
    );
  }
}
