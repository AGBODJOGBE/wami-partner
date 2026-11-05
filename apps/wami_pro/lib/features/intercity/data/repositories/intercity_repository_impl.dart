import 'package:wami_core/wami_core.dart';

import '../../domain/entities/intercity.dart';
import '../../domain/repositories/intercity_repository.dart';
import '../datasources/intercity_data_sources.dart';

class IntercityRepositoryImpl implements IntercityRepository {
  const IntercityRepositoryImpl(this._remote);
  final IntercityRemoteDataSource _remote;

  @override
  Future<Result<List<IntercityOffer>>> offers() => guard(_remote.offers);

  @override
  Future<Result<List<DailyRoute>>> routes() => guard(_remote.routes);

  @override
  Future<Result<IntercityOffer>> publish(OfferDraft draft) => guard(() => _remote.publish(draft));

  @override
  Future<Result<IntercityOffer>> start(String offerId) => guard(() => _remote.start(offerId));

  @override
  Future<Result<IntercityOffer>> complete(String offerId) => guard(() => _remote.complete(offerId));

  @override
  Future<Result<IntercityOffer>> cancel(String offerId, String reason) => guard(() => _remote.cancel(offerId, reason));

  @override
  Future<Result<DailyRoute>> createRoute(RouteDraft draft) => guard(() => _remote.createRoute(draft));

  @override
  Future<Result<DailyRoute>> pauseRoute(String routeId, DateTime? resumeDate) => guard(() => _remote.pauseRoute(routeId, resumeDate));

  @override
  Future<Result<DailyRoute>> resumeRoute(String routeId) => guard(() => _remote.resumeRoute(routeId));

  @override
  Future<Result<DailyRoute>> cancelRoute(String routeId, String reason) => guard(() => _remote.cancelRoute(routeId, reason));
}
