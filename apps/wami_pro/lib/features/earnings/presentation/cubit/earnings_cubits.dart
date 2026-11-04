import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../domain/entities/earnings.dart';
import '../../domain/usecases/earnings_usecases.dart';

/// État générique « donnée chargée » pour les écrans de consultation.
class DataState<T> extends Equatable {
  const DataState({this.status = LoadStatus.idle, this.data, this.failure, this.busy = false, this.done = false});
  final LoadStatus status;
  final T? data;
  final Failure? failure;
  final bool busy;

  /// Opération terminée avec succès (retrait…).
  final bool done;

  @override
  List<Object?> get props => [status, data, failure, busy, done];
}

class EarningsCubit extends Cubit<(EarningsPeriod, DataState<EarningsSummary>)> {
  EarningsCubit(this._get) : super((EarningsPeriod.week, const DataState()));
  final GetEarnings _get;

  Future<void> load([EarningsPeriod? period]) async {
    final p = period ?? state.$1;
    emit((p, DataState(status: LoadStatus.loading, data: state.$2.data)));
    final r = await _get(p);
    emit((p, r.fold((f) => DataState(status: LoadStatus.failure, failure: f), (d) => DataState(status: LoadStatus.ready, data: d))));
  }
}

class PartnerWalletCubit extends Cubit<DataState<PartnerWallet>> {
  PartnerWalletCubit(this._get, this._withdraw) : super(const DataState());
  final GetPartnerWallet _get;
  final WithdrawEarnings _withdraw;

  Future<void> load() async {
    emit(const DataState(status: LoadStatus.loading));
    final r = await _get(const NoParams());
    emit(r.fold((f) => DataState(status: LoadStatus.failure, failure: f), (w) => DataState(status: LoadStatus.ready, data: w)));
  }

  Future<void> withdrawAll() async {
    final w = state.data;
    if (w == null) return;
    emit(DataState(status: LoadStatus.ready, data: w, busy: true));
    final r = await _withdraw(WithdrawParams(wallet: w, amount: w.withdrawable));
    emit(r.fold(
      (f) => DataState(status: LoadStatus.ready, data: w, failure: f),
      (updated) => DataState(status: LoadStatus.ready, data: updated, done: true),
    ));
  }
}

class PerformanceCubit extends Cubit<DataState<Performance>> {
  PerformanceCubit(this._get) : super(const DataState());
  final GetPerformance _get;

  Future<void> load() async {
    emit(const DataState(status: LoadStatus.loading));
    final r = await _get(const NoParams());
    emit(r.fold((f) => DataState(status: LoadStatus.failure, failure: f), (p) => DataState(status: LoadStatus.ready, data: p)));
  }
}

/// Envoi d'argent : `done` passe à vrai après un transfert réussi, `data` porte le reçu.
class TransferCubit extends Cubit<DataState<TransferReceipt>> {
  TransferCubit(this._get, this._transfer) : super(const DataState());
  final GetPartnerWallet _get;
  final TransferMoney _transfer;

  Future<void> send({required String phone, required int amount, String? note}) async {
    emit(const DataState(busy: true));
    final wallet = await _get(const NoParams());
    final w = wallet.valueOrNull;
    if (w == null) {
      emit(DataState(failure: wallet.fold((f) => f, (_) => null)));
      return;
    }
    final r = await _transfer(TransferParams(wallet: w, phone: phone, amount: amount, note: note));
    emit(r.fold((f) => DataState(failure: f), (receipt) => DataState(status: LoadStatus.ready, data: receipt, done: true)));
  }
}
