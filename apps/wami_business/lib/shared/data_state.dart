import 'package:equatable/equatable.dart';
import 'package:wami_core/wami_core.dart';

/// État générique « donnée chargée » partagé par les cubits de consultation.
class DataState<T> extends Equatable {
  const DataState({this.status = LoadStatus.idle, this.data, this.failure, this.busy = false});
  final LoadStatus status;
  final T? data;
  final Failure? failure;

  /// Une action est en cours (bouton en chargement).
  final bool busy;

  DataState<T> loading() => DataState(status: LoadStatus.loading, data: data);
  DataState<T> ready(T value) => DataState(status: LoadStatus.ready, data: value);
  DataState<T> failed(Failure f) => DataState(status: data == null ? LoadStatus.failure : LoadStatus.ready, data: data, failure: f);
  DataState<T> working() => DataState(status: status, data: data, busy: true);

  /// Applique le résultat d'une action : nouvelle donnée ou message d'erreur.
  DataState<T> apply(Result<T> r) => r.fold(failed, ready);

  @override
  List<Object?> get props => [status, data, failure, busy];
}
