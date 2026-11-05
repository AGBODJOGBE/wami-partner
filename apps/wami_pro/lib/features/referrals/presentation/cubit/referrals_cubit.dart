import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../domain/entities/referral.dart';
import '../../domain/usecases/referrals_usecases.dart';

class ReferralsState extends Equatable {
  const ReferralsState({this.status = LoadStatus.idle, this.data, this.busy = false, this.failure, this.notice});
  final LoadStatus status;
  final ReferralOverview? data;
  final bool busy;
  final Failure? failure;
  final String? notice;

  @override
  List<Object?> get props => [status, data, busy, failure, notice];
}

class ReferralsCubit extends Cubit<ReferralsState> {
  ReferralsCubit(this._get, this._apply, this._validate) : super(const ReferralsState());
  final GetReferrals _get;
  final ApplyReferralCode _apply;
  final ValidateMyReferral _validate;

  Future<void> load() async {
    emit(ReferralsState(status: LoadStatus.loading, data: state.data));
    final r = await _get(const NoParams());
    emit(r.fold(
      (f) => ReferralsState(status: LoadStatus.failure, data: state.data, failure: f),
      (d) => ReferralsState(status: LoadStatus.ready, data: d),
    ));
  }

  Future<void> apply(String code) => _run(() => _apply(code));
  Future<void> validate() => _run(() => _validate(const NoParams()));

  Future<void> _run(Future<Result<String>> Function() action) async {
    emit(ReferralsState(status: LoadStatus.ready, data: state.data, busy: true));
    final r = await action();
    if (!r.isOk) {
      emit(ReferralsState(status: LoadStatus.ready, data: state.data, failure: r.fold((f) => f, (_) => null)));
      return;
    }
    await load();
    emit(ReferralsState(status: LoadStatus.ready, data: state.data, notice: r.valueOrNull));
  }
}
