import 'package:wami_core/wami_core.dart';

import '../entities/fare.dart';
import '../entities/mission.dart';
import '../repositories/missions_repository.dart';

/// Code du destinataire d'une livraison : 6 chiffres envoyés par SMS.
final _deliveryCode = RegExp(r'^\d{6}$');

class GetDriverDay implements UseCase<DriverDay, NoParams> {
  const GetDriverDay(this._repo);
  final MissionsRepository _repo;

  @override
  Future<Result<DriverDay>> call(NoParams _) => _repo.getDay();
}

class GetFarePolicy implements UseCase<FarePolicy, NoParams> {
  const GetFarePolicy(this._repo);
  final MissionsRepository _repo;

  @override
  Future<Result<FarePolicy>> call(NoParams _) => _repo.getFarePolicy();
}

class SetOnline implements UseCase<DriverDay, bool> {
  const SetOnline(this._repo);
  final MissionsRepository _repo;

  @override
  Future<Result<DriverDay>> call(bool online) => _repo.setOnline(online);
}

class WatchOffers implements StreamUseCase<MissionOffer, NoParams> {
  const WatchOffers(this._repo);
  final MissionsRepository _repo;

  @override
  Stream<MissionOffer> call(NoParams _) => _repo.offers();
}

class GetCurrentMission implements UseCase<ActiveMission?, NoParams> {
  const GetCurrentMission(this._repo);
  final MissionsRepository _repo;

  @override
  Future<Result<ActiveMission?>> call(NoParams _) => _repo.currentMission();
}

class WatchCancellations implements StreamUseCase<String, NoParams> {
  const WatchCancellations(this._repo);
  final MissionsRepository _repo;

  @override
  Stream<String> call(NoParams _) => _repo.cancellations();
}

class AcceptMission implements UseCase<ActiveMission, String> {
  const AcceptMission(this._repo);
  final MissionsRepository _repo;

  @override
  Future<Result<ActiveMission>> call(String id) => _repo.accept(id);
}

class DeclineMission implements UseCase<void, String> {
  const DeclineMission(this._repo);
  final MissionsRepository _repo;

  @override
  Future<Result<void>> call(String id) => _repo.decline(id);
}

class MarkArrived implements UseCase<ActiveMission, String> {
  const MarkArrived(this._repo);
  final MissionsRepository _repo;

  @override
  Future<Result<ActiveMission>> call(String id) => _repo.arrived(id);
}

class StartParams {
  const StartParams({required this.missionId, this.code = ''});
  final String missionId;

  /// Inutilisé : le serveur ne demande aucun code au départ d'une course.
  final String code;
}

/// Règle : une course ne démarre qu'avec le code à 4 chiffres du client.
class StartTrip implements UseCase<ActiveMission, StartParams> {
  const StartTrip(this._repo);
  final MissionsRepository _repo;

  @override
  Future<Result<ActiveMission>> call(StartParams p) => _repo.start(p.missionId, p.code);
}

class TogglePause implements UseCase<ActiveMission, ActiveMission> {
  const TogglePause(this._repo);
  final MissionsRepository _repo;

  @override
  Future<Result<ActiveMission>> call(ActiveMission m) async {
    if (m.offer.kind.isDelivery) return const Err(ValidationFailure('La pause concerne uniquement les courses.'));
    if (m.stage == MissionStage.inProgress) return _repo.pause(m.offer.id);
    if (m.stage == MissionStage.paused) return _repo.resume(m.offer.id);
    return const Err(ValidationFailure('La course n’a pas démarré.'));
  }
}

class PickupParams {
  const PickupParams({required this.mission, required this.checked, required this.photoTaken, this.photoPath});
  final ActiveMission mission;
  final Set<String> checked;
  final bool photoTaken;

  /// Fichier de la photo du colis (envoyé au serveur).
  final String? photoPath;
}

/// Règle : toute la liste de contrôle cochée, et photo prise pour un colis.
class ConfirmPickup implements UseCase<ActiveMission, PickupParams> {
  const ConfirmPickup(this._repo);
  final MissionsRepository _repo;

  @override
  Future<Result<ActiveMission>> call(PickupParams p) async {
    final items = PickupChecklist.itemsFor(p.mission.offer);
    if (!items.every(p.checked.contains)) return const Err(ValidationFailure('Cochez chaque point avant de partir.'));
    if (PickupChecklist.photoRequired(p.mission.offer) && !p.photoTaken) {
      return const Err(ValidationFailure('Prenez une photo du colis.'));
    }
    return _repo.confirmPickup(p.mission.offer.id, photoTaken: p.photoTaken, photoPath: p.photoPath);
  }
}

class CompleteTrip implements UseCase<MissionReceipt, String> {
  const CompleteTrip(this._repo);
  final MissionsRepository _repo;

  @override
  Future<Result<MissionReceipt>> call(String id) => _repo.complete(id);
}

class HandoverParams {
  const HandoverParams({required this.missionId, required this.code, required this.collectedWith, this.photoPath});
  final String missionId;
  final String code;
  final PaymentMode collectedWith;

  /// Photo de remise, exigée par le serveur pour clore la livraison.
  final String? photoPath;
}

class ConfirmHandover implements UseCase<MissionReceipt, HandoverParams> {
  const ConfirmHandover(this._repo);
  final MissionsRepository _repo;

  @override
  Future<Result<MissionReceipt>> call(HandoverParams p) async {
    if (!_deliveryCode.hasMatch(p.code)) return const Err(ValidationFailure('Saisissez le code à 6 chiffres du destinataire.'));
    return _repo.handover(p.missionId, code: p.code, collectedWith: p.collectedWith, photoPath: p.photoPath);
  }
}

class RateCustomerParams {
  const RateCustomerParams({required this.missionId, required this.stars});
  final String missionId;
  final int stars;
}

class RateCustomer implements UseCase<void, RateCustomerParams> {
  const RateCustomer(this._repo);
  final MissionsRepository _repo;

  @override
  Future<Result<void>> call(RateCustomerParams p) async {
    if (p.stars < 1 || p.stars > 5) return const Err(ValidationFailure('Note entre 1 et 5.'));
    return _repo.rateCustomer(p.missionId, p.stars);
  }
}

class CancelParams {
  const CancelParams({required this.missionId, this.reason});
  final String missionId;
  final String? reason;
}

class CancelMission implements UseCase<void, CancelParams> {
  const CancelMission(this._repo);
  final MissionsRepository _repo;

  @override
  Future<Result<void>> call(CancelParams p) => _repo.cancel(p.missionId, reason: p.reason);
}

class DeclareNoShow implements UseCase<void, String> {
  const DeclareNoShow(this._repo);
  final MissionsRepository _repo;

  @override
  Future<Result<void>> call(String missionId) => _repo.declareNoShow(missionId, reason: 'Client absent');
}

class FailureParams {
  const FailureParams({required this.missionId, required this.reason});
  final String missionId;
  final String reason;
}

/// Le serveur ne valide pas le motif mais le stocke : on l'exige toujours.
class ReportDeliveryFailure implements UseCase<ActiveMission, FailureParams> {
  const ReportDeliveryFailure(this._repo);
  final MissionsRepository _repo;

  @override
  Future<Result<ActiveMission>> call(FailureParams p) async {
    if (p.reason.trim().length < 3) return const Err(ValidationFailure('Indiquez le motif de l’échec.'));
    return _repo.reportFailure(p.missionId, p.reason.trim());
  }
}

class StartReturn implements UseCase<ActiveMission, String> {
  const StartReturn(this._repo);
  final MissionsRepository _repo;

  @override
  Future<Result<ActiveMission>> call(String id) => _repo.startReturn(id);
}

class CompleteReturn implements UseCase<void, String> {
  const CompleteReturn(this._repo);
  final MissionsRepository _repo;

  @override
  Future<Result<void>> call(String id) => _repo.completeReturn(id);
}

class WatchDestinationChanges implements StreamUseCase<DestinationChange, NoParams> {
  const WatchDestinationChanges(this._repo);
  final MissionsRepository _repo;

  @override
  Stream<DestinationChange> call(NoParams _) => _repo.destinationChanges();
}

class AnswerParams {
  const AnswerParams({required this.missionId, required this.accept});
  final String missionId;
  final bool accept;
}

class AnswerDestinationChange implements UseCase<ActiveMission, AnswerParams> {
  const AnswerDestinationChange(this._repo);
  final MissionsRepository _repo;

  @override
  Future<Result<ActiveMission>> call(AnswerParams p) => _repo.answerDestination(p.missionId, accept: p.accept);
}

class WatchHotZones implements StreamUseCase<String?, NoParams> {
  const WatchHotZones(this._repo);
  final MissionsRepository _repo;

  @override
  Stream<String?> call(NoParams _) => _repo.hotZones();
}

class EstimateDirectRide implements UseCase<DirectEstimate, DirectRideRequest> {
  const EstimateDirectRide(this._repo);
  final MissionsRepository _repo;

  @override
  Future<Result<DirectEstimate>> call(DirectRideRequest r) => _repo.estimateDirect(r);
}

class StartDirectRide implements UseCase<ActiveMission, DirectRideRequest> {
  const StartDirectRide(this._repo);
  final MissionsRepository _repo;

  @override
  Future<Result<ActiveMission>> call(DirectRideRequest r) => _repo.startDirect(r);
}
