import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../domain/entities/intercity.dart';
import '../../domain/usecases/intercity_usecases.dart';

class IntercityState extends Equatable {
  const IntercityState({this.status = LoadStatus.idle, this.offers = const [], this.routes = const [], this.busy = false, this.failure, this.notice});
  final LoadStatus status;
  final List<IntercityOffer> offers;
  final List<DailyRoute> routes;
  final bool busy;
  final Failure? failure;
  final String? notice;

  @override
  List<Object?> get props => [status, offers, routes, busy, failure, notice];
}

class IntercityCubit extends Cubit<IntercityState> {
  IntercityCubit({
    required GetOffers offers,
    required GetDailyRoutes routes,
    required PublishOffer publish,
    required StartOffer start,
    required CompleteOffer complete,
    required CancelOffer cancel,
    required CreateDailyRoute createRoute,
    required PauseDailyRoute pauseRoute,
    required ResumeDailyRoute resumeRoute,
    required CancelDailyRoute cancelRoute,
  })  : _offers = offers,
        _routes = routes,
        _publish = publish,
        _start = start,
        _complete = complete,
        _cancel = cancel,
        _createRoute = createRoute,
        _pauseRoute = pauseRoute,
        _resumeRoute = resumeRoute,
        _cancelRoute = cancelRoute,
        super(const IntercityState());

  final GetOffers _offers;
  final GetDailyRoutes _routes;
  final PublishOffer _publish;
  final StartOffer _start;
  final CompleteOffer _complete;
  final CancelOffer _cancel;
  final CreateDailyRoute _createRoute;
  final PauseDailyRoute _pauseRoute;
  final ResumeDailyRoute _resumeRoute;
  final CancelDailyRoute _cancelRoute;

  Future<void> load() async {
    emit(IntercityState(status: LoadStatus.loading, offers: state.offers, routes: state.routes));
    final o = await _offers(const NoParams());
    final r = await _routes(const NoParams());
    emit(IntercityState(status: LoadStatus.ready, offers: o.valueOrNull ?? state.offers, routes: r.valueOrNull ?? state.routes));
  }

  Future<bool> _act(Future<Result<Object?>> Function() action, String notice) async {
    emit(IntercityState(status: LoadStatus.ready, offers: state.offers, routes: state.routes, busy: true));
    final r = await action();
    if (!r.isOk) {
      emit(IntercityState(status: LoadStatus.ready, offers: state.offers, routes: state.routes, failure: r.fold((f) => f, (_) => null)));
      return false;
    }
    await load();
    emit(IntercityState(status: LoadStatus.ready, offers: state.offers, routes: state.routes, notice: notice));
    return true;
  }

  Future<bool> publish(OfferDraft d) => _act(() => _publish(d), 'Trajet publié.');
  Future<bool> start(String id) => _act(() => _start(id), 'Trajet démarré.');
  Future<bool> complete(String id) => _act(() => _complete(id), 'Trajet terminé.');
  Future<bool> cancel(String id, String reason) => _act(() => _cancel(OfferAction(id, reason)), 'Trajet annulé.');
  Future<bool> createRoute(RouteDraft d) => _act(() => _createRoute(d), 'Trajet quotidien créé.');
  Future<bool> pauseRoute(String id, DateTime? resume) => _act(() => _pauseRoute(PauseParams(id, resume)), 'Trajet mis en pause.');
  Future<bool> resumeRoute(String id) => _act(() => _resumeRoute(id), 'Trajet repris.');
  Future<bool> cancelRoute(String id, String reason) => _act(() => _cancelRoute(OfferAction(id, reason)), 'Trajet annulé.');
}
