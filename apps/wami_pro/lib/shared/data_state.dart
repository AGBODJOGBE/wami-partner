import 'package:equatable/equatable.dart';
import 'package:wami_core/wami_core.dart';

/// État générique « donnée chargée » des écrans de consultation (hors gains,
/// qui ont le leur : les features ne s'importent pas entre elles).
class DataState<T> extends Equatable {
  const DataState({this.status = LoadStatus.idle, this.data, this.failure, this.busy = false, this.done = false});
  final LoadStatus status;
  final T? data;
  final Failure? failure;
  final bool busy;

  /// Action terminée avec succès (transfert, changement de mot de passe…).
  final bool done;

  @override
  List<Object?> get props => [status, data, failure, busy, done];
}
