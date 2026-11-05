import 'package:wami_core/wami_core.dart';

import '../entities/intercity.dart';

/// Le serveur n'a aucune route pour LISTER les trajets du chauffeur : l'app garde sur l'appareil
/// ceux qu'elle a créés et met leur statut à jour avec les réponses du serveur.
abstract interface class IntercityRepository {
  Future<Result<List<IntercityOffer>>> offers();
  Future<Result<List<DailyRoute>>> routes();

  Future<Result<IntercityOffer>> publish(OfferDraft draft);
  Future<Result<IntercityOffer>> start(String offerId);
  Future<Result<IntercityOffer>> complete(String offerId);
  Future<Result<IntercityOffer>> cancel(String offerId, String reason);

  Future<Result<DailyRoute>> createRoute(RouteDraft draft);
  Future<Result<DailyRoute>> pauseRoute(String routeId, DateTime? resumeDate);
  Future<Result<DailyRoute>> resumeRoute(String routeId);
  Future<Result<DailyRoute>> cancelRoute(String routeId, String reason);
}
