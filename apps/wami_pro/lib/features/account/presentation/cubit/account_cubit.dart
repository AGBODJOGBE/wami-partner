import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../domain/entities/partner_account.dart';
import '../../domain/usecases/account_usecases.dart';

class AccountState extends Equatable {
  const AccountState({this.status = LoadStatus.idle, this.account, this.failure});
  final LoadStatus status;
  final PartnerAccount? account;
  final Failure? failure;

  @override
  List<Object?> get props => [status, account, failure];
}

class AccountCubit extends Cubit<AccountState> {
  AccountCubit(this._get, this._save) : super(const AccountState());
  final GetPartnerAccount _get;
  final SavePreferences _save;

  Future<void> load() async {
    emit(const AccountState(status: LoadStatus.loading));
    final r = await _get(const NoParams());
    emit(r.fold((f) => AccountState(status: LoadStatus.failure, failure: f), (a) => AccountState(status: LoadStatus.ready, account: a)));
  }

  /// Enregistrement optimiste : on affiche tout de suite, on revient en arrière si erreur.
  Future<void> updatePreferences(PartnerPreferences Function(PartnerPreferences p) change) async {
    final a = state.account;
    if (a == null) return;
    final next = change(a.preferences);
    emit(AccountState(status: LoadStatus.ready, account: a.copyWith(preferences: next)));
    final r = await _save(next);
    if (!r.isOk) emit(AccountState(status: LoadStatus.ready, account: a, failure: r.fold((f) => f, (_) => null)));
  }
}

/// Changement de mot de passe (`PUT /api/drivers/password`).
class PasswordCubit extends Cubit<AccountState> {
  PasswordCubit(this._change) : super(const AccountState());
  final ChangePassword _change;

  /// `true` si le mot de passe a été changé.
  Future<bool> submit({required String current, required String next, required String confirm}) async {
    emit(const AccountState(status: LoadStatus.loading));
    final r = await _change(ChangePasswordParams(current: current, next: next, confirm: confirm));
    emit(AccountState(status: r.isOk ? LoadStatus.ready : LoadStatus.failure, failure: r.fold((f) => f, (_) => null)));
    return r.isOk;
  }
}
