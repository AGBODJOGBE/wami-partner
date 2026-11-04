import 'package:wami_core/wami_core.dart';

import '../entities/fare.dart';
import '../entities/mission.dart';

abstract interface class MissionsRepository {
  Future<Result<DriverDay>> getDay();
  Future<Result<FarePolicy>> getFarePolicy();
  Future<Result<DriverDay>> setOnline(bool online);

  /// Flux des missions proposées tant que le partenaire est en ligne
  /// (WebSocket en production).
  Stream<MissionOffer> offers();

  Future<Result<ActiveMission>> accept(String offerId);
  Future<Result<void>> decline(String offerId, {String? reason});
  Future<Result<ActiveMission>> arrived(String missionId);

  /// Démarrage d'une course avec le code donné par le client.
  Future<Result<ActiveMission>> start(String missionId, String customerCode);
  Future<Result<ActiveMission>> pause(String missionId);
  Future<Result<ActiveMission>> resume(String missionId);

  /// Collecte d'une livraison (liste de contrôle et photo).
  Future<Result<ActiveMission>> confirmPickup(String missionId, {required bool photoTaken});

  /// Fin de course.
  Future<Result<MissionReceipt>> complete(String missionId);

  /// Remise d'une livraison avec le code du destinataire.
  Future<Result<MissionReceipt>> handover(String missionId, {required String code, required PaymentMode collectedWith});

  Future<Result<void>> rateCustomer(String missionId, int stars);
}
