import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/data_state.dart';
import '../../domain/entities/business_account.dart';
import '../../domain/usecases/account_usecases.dart';

class AccountCubit extends Cubit<DataState<BusinessAccount>> {
  AccountCubit(this._get, this._invite, this._remove) : super(const DataState());
  final GetBusinessAccount _get;
  final InviteMember _invite;
  final RemoveMember _remove;

  Future<void> load() async {
    emit(state.loading());
    emit(state.apply(await _get(const NoParams())));
  }

  Future<bool> invite({required String name, required String phone, required TeamRole role}) async {
    final a = state.data;
    if (a == null) return false;
    emit(state.working());
    final r = await _invite(InviteParams(team: a.team, name: name, phone: phone, role: role));
    r.fold(
      (f) => emit(state.failed(f)),
      (m) => emit(state.ready(a.copyWith(team: [...a.team, m]))),
    );
    return r.isOk;
  }

  Future<void> remove(TeamMember m) async {
    final a = state.data;
    if (a == null) return;
    emit(state.working());
    final r = await _remove(m);
    r.fold(
      (f) => emit(state.failed(f)),
      (_) => emit(state.ready(a.copyWith(team: a.team.where((x) => x.id != m.id).toList()))),
    );
  }
}
