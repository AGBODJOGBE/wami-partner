import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../domain/entities/mission.dart';
import '../../domain/usecases/missions_usecases.dart';

class DirectRideState extends Equatable {
  const DirectRideState({this.destination, this.estimate, this.busy = false, this.failure});
  final DirectRideRequest? destination;
  final DirectEstimate? estimate;
  final bool busy;
  final Failure? failure;

  @override
  List<Object?> get props => [destination, estimate, busy, failure];
}

/// Course directe : le client est devant le chauffeur, sans l'app. Départ = position du chauffeur.
class DirectRideCubit extends Cubit<DirectRideState> {
  DirectRideCubit(this._estimate, this._start) : super(const DirectRideState());
  final EstimateDirectRide _estimate;
  final StartDirectRide _start;

  Future<void> choose(DirectRideRequest destination) async {
    emit(DirectRideState(destination: destination, busy: true));
    final r = await _estimate(destination);
    emit(r.fold(
      (f) => DirectRideState(destination: destination, failure: f),
      (e) => DirectRideState(destination: destination, estimate: e),
    ));
  }

  /// La course est créée « chauffeur arrivé » ; renvoie la mission ou `null` en cas d'échec.
  Future<ActiveMission?> begin() async {
    final d = state.destination;
    if (d == null) return null;
    emit(DirectRideState(destination: d, estimate: state.estimate, busy: true));
    final r = await _start(d);
    emit(DirectRideState(destination: d, estimate: state.estimate, failure: r.fold((f) => f, (_) => null)));
    return r.valueOrNull;
  }
}
