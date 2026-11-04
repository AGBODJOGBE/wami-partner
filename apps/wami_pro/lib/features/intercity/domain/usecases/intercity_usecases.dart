import 'package:wami_core/wami_core.dart';

import '../entities/intercity.dart';
import '../repositories/intercity_repository.dart';

class GetOffers implements UseCase<List<IntercityOffer>, NoParams> {
  const GetOffers(this._repo);
  final IntercityRepository _repo;

  @override
  Future<Result<List<IntercityOffer>>> call(NoParams _) => _repo.offers();
}

class GetDailyRoutes implements UseCase<List<DailyRoute>, NoParams> {
  const GetDailyRoutes(this._repo);
  final IntercityRepository _repo;

  @override
  Future<Result<List<DailyRoute>>> call(NoParams _) => _repo.routes();
}

class PublishOffer implements UseCase<IntercityOffer, OfferDraft> {
  const PublishOffer(this._repo);
  final IntercityRepository _repo;

  @override
  Future<Result<IntercityOffer>> call(OfferDraft d) async {
    if (d.origin.city == d.destination.city) return const Err(ValidationFailure('Choisissez deux villes différentes.'));
    if (!d.departure.isAfter(DateTime.now())) return const Err(ValidationFailure('Le départ doit être dans le futur.'));
    if (d.seats < 1 || d.seats > 6) return const Err(ValidationFailure('Entre 1 et 6 places.'));
    if (d.pricePerSeat <= 0) return const Err(ValidationFailure('Indiquez le prix par place.'));
    return _repo.publish(d);
  }
}

class OfferAction {
  const OfferAction(this.offerId, [this.reason]);
  final String offerId;
  final String? reason;
}

class StartOffer implements UseCase<IntercityOffer, String> {
  const StartOffer(this._repo);
  final IntercityRepository _repo;

  @override
  Future<Result<IntercityOffer>> call(String id) => _repo.start(id);
}

class CompleteOffer implements UseCase<IntercityOffer, String> {
  const CompleteOffer(this._repo);
  final IntercityRepository _repo;

  @override
  Future<Result<IntercityOffer>> call(String id) => _repo.complete(id);
}

/// Le serveur exige un motif d'au moins 5 caractères pour annuler.
class CancelOffer implements UseCase<IntercityOffer, OfferAction> {
  const CancelOffer(this._repo);
  final IntercityRepository _repo;

  @override
  Future<Result<IntercityOffer>> call(OfferAction a) async {
    final reason = a.reason?.trim() ?? '';
    if (reason.length < 5) return const Err(ValidationFailure('Motif : 5 caractères au moins.'));
    return _repo.cancel(a.offerId, reason);
  }
}

class CreateDailyRoute implements UseCase<DailyRoute, RouteDraft> {
  const CreateDailyRoute(this._repo);
  final IntercityRepository _repo;

  @override
  Future<Result<DailyRoute>> call(RouteDraft d) async {
    if (d.passengerId.trim().isEmpty) return const Err(ValidationFailure('Indiquez l’identifiant du passager.'));
    if (d.days.isEmpty) return const Err(ValidationFailure('Choisissez au moins un jour.'));
    if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(d.time)) return const Err(ValidationFailure('Heure invalide.'));
    if (d.pricePerRide <= 0) return const Err(ValidationFailure('Indiquez le prix par trajet.'));
    return _repo.createRoute(d);
  }
}

class PauseParams {
  const PauseParams(this.routeId, this.resumeDate);
  final String routeId;
  final DateTime? resumeDate;
}

class PauseDailyRoute implements UseCase<DailyRoute, PauseParams> {
  const PauseDailyRoute(this._repo);
  final IntercityRepository _repo;

  @override
  Future<Result<DailyRoute>> call(PauseParams p) async {
    final d = p.resumeDate;
    if (d != null && !d.isAfter(DateTime.now())) return const Err(ValidationFailure('La reprise doit être dans le futur.'));
    return _repo.pauseRoute(p.routeId, d);
  }
}

class ResumeDailyRoute implements UseCase<DailyRoute, String> {
  const ResumeDailyRoute(this._repo);
  final IntercityRepository _repo;

  @override
  Future<Result<DailyRoute>> call(String id) => _repo.resumeRoute(id);
}

class CancelDailyRoute implements UseCase<DailyRoute, OfferAction> {
  const CancelDailyRoute(this._repo);
  final IntercityRepository _repo;

  @override
  Future<Result<DailyRoute>> call(OfferAction a) async {
    final reason = a.reason?.trim() ?? '';
    if (reason.length < 5) return const Err(ValidationFailure('Motif : 5 caractères au moins.'));
    return _repo.cancelRoute(a.offerId, reason);
  }
}
