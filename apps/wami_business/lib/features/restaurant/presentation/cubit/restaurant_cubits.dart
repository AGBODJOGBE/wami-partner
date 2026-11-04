import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/data_state.dart';
import '../../domain/entities/order.dart';
import '../../domain/usecases/restaurant_usecases.dart';

class OrdersState extends Equatable {
  OrdersState({
    this.status = LoadStatus.idle,
    this.orders = const [],
    this.column = OrderStatus.incoming,
    DateTime? now,
    this.busyId,
    this.failure,
  }) : now = now ?? DateTime.now();

  final LoadStatus status;
  final List<FoodOrder> orders;

  /// Colonne affichée : nouvelles, en cuisine ou prêtes.
  final OrderStatus column;
  final DateTime now;
  final String? busyId;
  final Failure? failure;

  List<FoodOrder> of(OrderStatus s) => orders.where((o) => o.status == s).toList();
  List<FoodOrder> get visible => of(column);

  OrdersState copyWith({
    LoadStatus? status,
    List<FoodOrder>? orders,
    OrderStatus? column,
    DateTime? now,
    String? busyId,
    bool clearBusy = false,
    Failure? failure,
  }) {
    return OrdersState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      column: column ?? this.column,
      now: now ?? this.now,
      busyId: clearBusy ? null : (busyId ?? this.busyId),
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [status, orders, column, now, busyId, failure];
}

/// Tableau des commandes. Horloge chaque seconde (comptes à rebours),
/// relecture toutes les 4 s (à remplacer par du push, voir la source API).
class OrdersCubit extends Cubit<OrdersState> {
  OrdersCubit({
    required GetOrders getOrders,
    required AcceptOrder accept,
    required RejectOrder reject,
    required ExtendPrep extend,
    required MarkOrderReady markReady,
  })  : _getOrders = getOrders,
        _accept = accept,
        _reject = reject,
        _extend = extend,
        _markReady = markReady,
        super(OrdersState());

  final GetOrders _getOrders;
  final AcceptOrder _accept;
  final RejectOrder _reject;
  final ExtendPrep _extend;
  final MarkOrderReady _markReady;
  Timer? _clock;
  late String _establishmentId;
  var _ticks = 0;

  Future<void> watch(String establishmentId) async {
    _establishmentId = establishmentId;
    emit(state.copyWith(status: LoadStatus.loading));
    await _refresh();
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      emit(state.copyWith(now: DateTime.now(), failure: state.failure));
      if (++_ticks % 4 == 0) _refresh();
    });
  }

  Future<void> _refresh() async {
    final r = await _getOrders(_establishmentId);
    if (isClosed) return;
    r.fold(
      (f) => emit(state.copyWith(status: state.orders.isEmpty ? LoadStatus.failure : LoadStatus.ready, failure: f)),
      (orders) => emit(state.copyWith(status: LoadStatus.ready, orders: orders)),
    );
  }

  Future<void> retry() async {
    emit(state.copyWith(status: LoadStatus.loading));
    await _refresh();
  }

  void showColumn(OrderStatus s) => emit(state.copyWith(column: s));

  Future<bool> accept(FoodOrder o, int minutes) => _run(o, () => _accept(AcceptParams(o, minutes)));
  Future<bool> reject(FoodOrder o, String reason) => _run(o, () => _reject(RejectParams(o, reason)));
  Future<bool> extend(FoodOrder o) => _run(o, () => _extend(o));
  Future<bool> markReady(FoodOrder o) => _run(o, () => _markReady(o));

  Future<bool> _run(FoodOrder o, Future<Result<FoodOrder>> Function() action) async {
    emit(state.copyWith(busyId: o.id));
    final r = await action();
    if (isClosed) return false;
    r.fold(
      (f) => emit(state.copyWith(clearBusy: true, failure: f)),
      (updated) => emit(state.copyWith(
        clearBusy: true,
        orders: [for (final x in state.orders) x.id == updated.id ? updated : x],
      )),
    );
    return r.isOk;
  }

  @override
  Future<void> close() {
    _clock?.cancel();
    return super.close();
  }
}

class MenuCubit extends Cubit<DataState<RestaurantMenu>> {
  MenuCubit(this._get, this._setAvailability, this._setPaused) : super(const DataState());
  final GetMenu _get;
  final SetItemAvailability _setAvailability;
  final SetOrdersPaused _setPaused;
  late String _establishmentId;

  Future<void> load(String establishmentId) async {
    _establishmentId = establishmentId;
    emit(state.loading());
    emit(state.apply(await _get(establishmentId)));
  }

  /// Optimiste : un plat épuisé doit disparaître de l'app client sans attendre.
  Future<void> setAvailable(MenuItem item, bool available) async {
    final menu = state.data;
    if (menu == null) return;
    emit(state.ready(menu.copyWith(items: [for (final i in menu.items) i.id == item.id ? i.copyWith(available: available) : i])));
    final r = await _setAvailability(AvailabilityParams(item, available));
    if (!r.isOk) emit(DataState(status: LoadStatus.ready, data: menu, failure: r.fold((f) => f, (_) => null)));
  }

  Future<void> setPaused(bool paused) async {
    final menu = state.data;
    if (menu == null) return;
    emit(state.ready(menu.copyWith(paused: paused)));
    final r = await _setPaused(PauseParams(_establishmentId, paused));
    if (!r.isOk) emit(DataState(status: LoadStatus.ready, data: menu, failure: r.fold((f) => f, (_) => null)));
  }
}
