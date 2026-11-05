import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../domain/entities/history.dart';
import '../../domain/usecases/history_usecases.dart';

enum HistoryTab { rides, deliveries }

class HistoryState extends Equatable {
  const HistoryState({
    this.tab = HistoryTab.rides,
    this.filter,
    this.status = LoadStatus.idle,
    this.rides = const [],
    this.deliveries = const [],
    this.failure,
  });

  final HistoryTab tab;

  /// Filtre sur le résultat ; `null` = tout.
  final HistoryOutcome? filter;
  final LoadStatus status;
  final List<HistoryRide> rides;
  final List<HistoryDelivery> deliveries;
  final Failure? failure;

  List<HistoryRide> get shownRides => filter == null ? rides : rides.where((r) => r.outcome == filter).toList();
  List<HistoryDelivery> get shownDeliveries => filter == null ? deliveries : deliveries.where((d) => d.outcome == filter).toList();

  HistoryState copyWith({HistoryTab? tab, HistoryOutcome? filter, bool clearFilter = false, LoadStatus? status, List<HistoryRide>? rides, List<HistoryDelivery>? deliveries, Failure? failure}) =>
      HistoryState(
        tab: tab ?? this.tab,
        filter: clearFilter ? null : (filter ?? this.filter),
        status: status ?? this.status,
        rides: rides ?? this.rides,
        deliveries: deliveries ?? this.deliveries,
        failure: failure,
      );

  @override
  List<Object?> get props => [tab, filter, status, rides, deliveries, failure];
}

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit(this._rides, this._deliveries) : super(const HistoryState());
  final GetRideHistory _rides;
  final GetDeliveryHistory _deliveries;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    final r = await _rides(const NoParams());
    final d = await _deliveries(const NoParams());
    emit(state.copyWith(
      status: r.isOk || d.isOk ? LoadStatus.ready : LoadStatus.failure,
      rides: r.valueOrNull,
      deliveries: d.valueOrNull,
      failure: r.fold((f) => f, (_) => null) ?? d.fold((f) => f, (_) => null),
    ));
  }

  void setTab(HistoryTab t) => emit(state.copyWith(tab: t));
  void setFilter(HistoryOutcome? f) => emit(f == null ? state.copyWith(clearFilter: true) : state.copyWith(filter: f));
}
