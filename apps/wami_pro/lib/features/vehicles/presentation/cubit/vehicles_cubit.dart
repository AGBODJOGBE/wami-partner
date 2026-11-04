import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../domain/entities/vehicle.dart';
import '../../domain/usecases/vehicles_usecases.dart';

class VehiclesState extends Equatable {
  const VehiclesState({this.status = LoadStatus.idle, this.items = const [], this.busy = false, this.failure, this.notice});
  final LoadStatus status;
  final List<VehicleItem> items;
  final bool busy;
  final Failure? failure;

  /// Message de réussite à afficher une fois.
  final String? notice;

  @override
  List<Object?> get props => [status, items, busy, failure, notice];
}

class VehiclesCubit extends Cubit<VehiclesState> {
  VehiclesCubit(this._list, this._add, this._setActive, this._setCategories, this._upgrade, this._delete) : super(const VehiclesState());
  final ListVehicles _list;
  final AddVehicle _add;
  final SetActiveVehicle _setActive;
  final SetVehicleCategories _setCategories;
  final RequestCategoryUpgrade _upgrade;
  final DeleteVehicle _delete;

  Future<void> load() async {
    emit(VehiclesState(status: LoadStatus.loading, items: state.items));
    final r = await _list(const NoParams());
    emit(r.fold(
      (f) => VehiclesState(status: LoadStatus.failure, items: state.items, failure: f),
      (items) => VehiclesState(status: LoadStatus.ready, items: items),
    ));
  }

  /// Exécute une action puis recharge la liste ; `notice` s'affiche en cas de réussite.
  Future<bool> _act(Future<Result<Object?>> Function() action, {String? notice}) async {
    emit(VehiclesState(status: LoadStatus.ready, items: state.items, busy: true));
    final r = await action();
    if (!r.isOk) {
      emit(VehiclesState(status: LoadStatus.ready, items: state.items, failure: r.fold((f) => f, (_) => null)));
      return false;
    }
    await load();
    if (notice != null) emit(VehiclesState(status: LoadStatus.ready, items: state.items, notice: notice));
    return true;
  }

  Future<bool> add(NewVehicle v) => _act(() => _add(v), notice: 'Véhicule ajouté : il sera vérifié par WAMI.');
  Future<bool> activate(String id) => _act(() => _setActive(id), notice: 'Véhicule actif modifié.');
  Future<bool> setCategories(String id, List<VehicleCategory> c) =>
      _act(() => _setCategories(CategoriesParams(id, c)), notice: 'Catégories enregistrées.');
  Future<bool> remove(String id) => _act(() => _delete(id), notice: 'Véhicule supprimé.');

  Future<void> requestUpgrade(String id, VehicleCategory c, String? reason) async {
    emit(VehiclesState(status: LoadStatus.ready, items: state.items, busy: true));
    final r = await _upgrade(UpgradeParams(id, c, reason));
    emit(VehiclesState(
      status: LoadStatus.ready,
      items: state.items,
      failure: r.fold((f) => f, (_) => null),
      notice: r.valueOrNull,
    ));
  }
}
