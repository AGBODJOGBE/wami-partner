import 'package:wami_core/wami_core.dart';

import '../../domain/entities/fare.dart';
import '../../domain/entities/mission.dart';
import '../../domain/repositories/missions_repository.dart';
import '../datasources/missions_data_sources.dart';

class MissionsRepositoryImpl implements MissionsRepository {
  const MissionsRepositoryImpl(this._remote);
  final MissionsRemoteDataSource _remote;

  @override
  Future<Result<DriverDay>> getDay() => guard(_remote.day);

  @override
  Future<Result<FarePolicy>> getFarePolicy() => guard(_remote.farePolicy);

  @override
  Future<Result<DriverDay>> setOnline(bool online) => guard(() => _remote.setOnline(online));

  @override
  Stream<MissionOffer> offers() => _remote.offers();

  @override
  Future<Result<ActiveMission?>> currentMission() => guard(_remote.currentMission);

  @override
  Stream<String> cancellations() => _remote.cancellations();

  @override
  Future<Result<ActiveMission>> accept(String offerId) => guard(() => _remote.accept(offerId));

  @override
  Future<Result<void>> decline(String offerId, {String? reason}) => guard(() => _remote.decline(offerId, reason));

  @override
  Future<Result<ActiveMission>> arrived(String missionId) => guard(() => _remote.arrived(missionId));

  @override
  Future<Result<ActiveMission>> start(String missionId, String customerCode) =>
      guard(() => _remote.start(missionId, customerCode));

  @override
  Future<Result<ActiveMission>> pause(String missionId) => guard(() => _remote.pause(missionId));

  @override
  Future<Result<ActiveMission>> resume(String missionId) => guard(() => _remote.resume(missionId));

  @override
  Future<Result<ActiveMission>> confirmPickup(String missionId, {required bool photoTaken, String? photoPath}) =>
      guard(() => _remote.confirmPickup(missionId, photoTaken, photoPath));

  @override
  Future<Result<MissionReceipt>> complete(String missionId) => guard(() => _remote.complete(missionId));

  @override
  Future<Result<MissionReceipt>> handover(
    String missionId, {
    required String code,
    required PaymentMode collectedWith,
    String? photoPath,
  }) =>
      guard(() => _remote.handover(missionId, code, collectedWith, photoPath));

  @override
  Future<Result<void>> rateCustomer(String missionId, int stars) => guard(() => _remote.rate(missionId, stars));

  @override
  Future<Result<void>> cancel(String missionId, {String? reason}) => guard(() => _remote.cancel(missionId, reason));

  @override
  Future<Result<void>> declareNoShow(String missionId, {String? reason}) => guard(() => _remote.noShow(missionId, reason));

  @override
  Future<Result<ActiveMission>> reportFailure(String missionId, String reason) =>
      guard(() => _remote.reportFailure(missionId, reason));

  @override
  Future<Result<ActiveMission>> startReturn(String missionId) => guard(() => _remote.startReturn(missionId));

  @override
  Future<Result<void>> completeReturn(String missionId) => guard(() => _remote.completeReturn(missionId));

  @override
  Stream<DestinationChange> destinationChanges() => _remote.destinationChanges();

  @override
  Future<Result<ActiveMission>> answerDestination(String missionId, {required bool accept, String? reason}) =>
      guard(() => _remote.answerDestination(missionId, accept, reason));

  @override
  Stream<String?> hotZones() => _remote.hotZones();

  @override
  Future<Result<DirectEstimate>> estimateDirect(DirectRideRequest request) => guard(() => _remote.estimateDirect(request));

  @override
  Future<Result<ActiveMission>> startDirect(DirectRideRequest request) => guard(() => _remote.startDirect(request));
}
