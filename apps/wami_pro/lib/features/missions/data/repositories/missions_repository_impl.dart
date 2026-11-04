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
}
