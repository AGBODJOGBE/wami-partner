import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../domain/entities/driver_profile.dart';
import '../../domain/usecases/profile_usecases.dart';

class ProfileState extends Equatable {
  const ProfileState({this.status = LoadStatus.idle, this.profile, this.busy = false, this.failure, this.notice});
  final LoadStatus status;
  final DriverProfile? profile;
  final bool busy;
  final Failure? failure;
  final String? notice;

  @override
  List<Object?> get props => [status, profile, busy, failure, notice];
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._get, this._update, this._delete) : super(const ProfileState());
  final GetProfile _get;
  final UpdateProfile _update;
  final DeleteAccount _delete;

  Future<void> load() async {
    emit(ProfileState(status: LoadStatus.loading, profile: state.profile));
    final r = await _get(const NoParams());
    emit(r.fold(
      (f) => ProfileState(status: LoadStatus.failure, profile: state.profile, failure: f),
      (p) => ProfileState(status: LoadStatus.ready, profile: p),
    ));
  }

  /// `true` si le serveur a accepté la modification (le profil est alors relu).
  Future<bool> change(ProfileChange c) async {
    emit(ProfileState(status: LoadStatus.ready, profile: state.profile, busy: true));
    final r = await _update(c);
    if (!r.isOk) {
      emit(ProfileState(status: LoadStatus.ready, profile: state.profile, failure: r.fold((f) => f, (_) => null)));
      return false;
    }
    final notice = r.valueOrNull;
    await load();
    emit(ProfileState(status: LoadStatus.ready, profile: state.profile, notice: notice));
    return true;
  }

  /// `true` si le compte est supprimé : l'appelant doit alors fermer la session.
  Future<bool> deleteAccount(String password) async {
    emit(ProfileState(status: LoadStatus.ready, profile: state.profile, busy: true));
    final r = await _delete(password);
    emit(ProfileState(status: LoadStatus.ready, profile: state.profile, failure: r.fold((f) => f, (_) => null)));
    return r.isOk;
  }
}
