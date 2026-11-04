import 'package:wami_core/wami_core.dart';

import '../entities/fare.dart';
import '../entities/mission.dart';
import '../repositories/missions_repository.dart';

final _code = RegExp(r'^\d{4}$');

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
  const StartParams({required this.missionId, required this.code});
  final String missionId;
  final String code;
}

/// Règle : une course ne démarre qu'avec le code à 4 chiffres du client.
class StartTrip implements UseCase<ActiveMission, StartParams> {
  const StartTrip(this._repo);
  final MissionsRepository _repo;

  @override
  Future<Result<ActiveMission>> call(StartParams p) async {
    if (!_code.hasMatch(p.code)) return const Err(ValidationFailure('Demandez au client son code à 4 chiffres.'));
    return _repo.start(p.missionId, p.code);
  }
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
  const PickupParams({required this.mission, required this.checked, required this.photoTaken});
  final ActiveMission mission;
  final Set<String> checked;
  final bool photoTaken;
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
    return _repo.confirmPickup(p.mission.offer.id, photoTaken: p.photoTaken);
  }
}

class CompleteTrip implements UseCase<MissionReceipt, String> {
  const CompleteTrip(this._repo);
  final MissionsRepository _repo;

  @override
  Future<Result<MissionReceipt>> call(String id) => _repo.complete(id);
}

class HandoverParams {
  const HandoverParams({required this.missionId, required this.code, required this.collectedWith});
  final String missionId;
  final String code;
  final PaymentMode collectedWith;
}

class ConfirmHandover implements UseCase<MissionReceipt, HandoverParams> {
  const ConfirmHandover(this._repo);
  final MissionsRepository _repo;

  @override
  Future<Result<MissionReceipt>> call(HandoverParams p) async {
    if (!_code.hasMatch(p.code)) return const Err(ValidationFailure('Saisissez le code à 4 chiffres du destinataire.'));
    return _repo.handover(p.missionId, code: p.code, collectedWith: p.collectedWith);
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
