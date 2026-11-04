import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/data_state.dart';
import '../../domain/entities/bonus.dart';
import '../../domain/usecases/bonus_usecases.dart';

class BonusCubit extends Cubit<DataState<BonusOverview>> {
  BonusCubit(this._get, this._consolidate) : super(const DataState());
  final GetBonusOverview _get;
  final ConsolidateBonus _consolidate;

  Future<void> load() async {
    emit(DataState(status: LoadStatus.loading, data: state.data));
    final r = await _get(const NoParams());
    emit(r.fold((f) => DataState(status: LoadStatus.failure, failure: f), (d) => DataState(status: LoadStatus.ready, data: d)));
  }

  /// Transfère tout le solde de bonus vers le solde principal, puis recharge.
  Future<void> consolidateAll() async {
    final b = state.data;
    if (b == null || state.busy) return;
    emit(DataState(status: LoadStatus.ready, data: b, busy: true));
    final r = await _consolidate(b.bonusBalance);
    if (!r.isOk) {
      emit(DataState(status: LoadStatus.ready, data: b, failure: r.fold((f) => f, (_) => null)));
      return;
    }
    await load();
    emit(DataState(status: LoadStatus.ready, data: state.data, done: true));
  }
}
