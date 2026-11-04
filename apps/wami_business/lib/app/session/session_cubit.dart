import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../features/onboarding/domain/entities/business.dart';
import '../../features/onboarding/domain/usecases/onboarding_usecases.dart';

enum SessionPhase { unknown, signedOut, onboarding, active }

class SessionState extends Equatable {
  const SessionState({this.phase = SessionPhase.unknown});
  final SessionPhase phase;

  @override
  List<Object?> get props => [phase];
}

/// Pilote les redirections : inscription et vérification tant que le compte
/// n'est pas actif, application complète ensuite.
class SessionCubit extends Cubit<SessionState> {
  SessionCubit(this._getSession, this._logout) : super(const SessionState());
  final GetSession _getSession;
  final Logout _logout;

  Future<void> load() async {
    final r = await _getSession(const NoParams());
    emit(SessionState(phase: switch (r.valueOrNull?.status) {
      null => SessionPhase.signedOut,
      BusinessStatus.active => SessionPhase.active,
      BusinessStatus.newcomer || BusinessStatus.verifying || BusinessStatus.suspended => SessionPhase.onboarding,
    }));
  }

  void markOnboarding() => emit(const SessionState(phase: SessionPhase.onboarding));
  void markActive() => emit(const SessionState(phase: SessionPhase.active));

  Future<void> logout() async {
    await _logout(const NoParams());
    emit(const SessionState(phase: SessionPhase.signedOut));
  }
}
