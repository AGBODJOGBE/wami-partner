import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/data_state.dart';
import '../../domain/entities/establishment.dart';
import '../../domain/usecases/establishments_usecases.dart';

class EstablishmentState extends Equatable {
  const EstablishmentState({this.status = LoadStatus.idle, this.items = const [], this.currentId, this.failure});
  final LoadStatus status;
  final List<Establishment> items;
  final String? currentId;
  final Failure? failure;

  Establishment? get current {
    for (final e in items) {
      if (e.id == currentId) return e;
    }
    return items.isEmpty ? null : items.first;
  }

  EstablishmentState copyWith({LoadStatus? status, List<Establishment>? items, String? currentId, Failure? failure}) =>
      EstablishmentState(
        status: status ?? this.status,
        items: items ?? this.items,
        currentId: currentId ?? this.currentId,
        failure: failure,
      );

  @override
  List<Object?> get props => [status, items, currentId, failure];
}

/// Établissement courant, partagé par tous les onglets.
class EstablishmentCubit extends Cubit<EstablishmentState> {
  EstablishmentCubit(this._get, this._setOpen) : super(const EstablishmentState());
  final GetEstablishments _get;
  final SetEstablishmentOpen _setOpen;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    final r = await _get(const NoParams());
    r.fold(
      (f) => emit(state.copyWith(status: LoadStatus.failure, failure: f)),
      (items) => emit(state.copyWith(status: LoadStatus.ready, items: items, currentId: state.currentId ?? items.firstOrNull?.id)),
    );
  }

  void select(String id) => emit(state.copyWith(currentId: id));

  void clear() => emit(const EstablishmentState());

  /// Optimiste : l'interrupteur bascule tout de suite, revient en arrière si le serveur refuse.
  Future<void> setOpen(bool open) async {
    final e = state.current;
    if (e == null) return;
    final before = state.items;
    emit(state.copyWith(items: _replace(before, e.copyWith(open: open))));
    final r = await _setOpen(SetOpenParams(e, open));
    r.fold(
      (f) => emit(state.copyWith(items: before, failure: f)),
      (saved) => emit(state.copyWith(items: _replace(state.items, saved))),
    );
  }

  static List<Establishment> _replace(List<Establishment> list, Establishment e) => [for (final x in list) x.id == e.id ? e : x];
}

class DashboardCubit extends Cubit<DataState<DashboardSnapshot>> {
  DashboardCubit(this._get) : super(const DataState());
  final GetDashboard _get;

  Future<void> load(String establishmentId) async {
    emit(state.loading());
    emit(state.apply(await _get(establishmentId)));
  }
}
