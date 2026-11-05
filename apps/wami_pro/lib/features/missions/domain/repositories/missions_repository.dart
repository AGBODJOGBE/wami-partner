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

  /// Mission en cours à reprendre au démarrage (course ou livraison), s'il y en a une.
  Future<Result<ActiveMission?>> currentMission();

  /// Missions annulées par le client pendant qu'elles sont en cours (identifiants).
  Stream<String> cancellations();

  Future<Result<ActiveMission>> accept(String offerId);
  Future<Result<void>> decline(String offerId, {String? reason});
  Future<Result<ActiveMission>> arrived(String missionId);

  /// Démarrage d'une course (le serveur n'attend pas de code du client).
  Future<Result<ActiveMission>> start(String missionId, String customerCode);
  Future<Result<ActiveMission>> pause(String missionId);
  Future<Result<ActiveMission>> resume(String missionId);

  /// Collecte d'une livraison (liste de contrôle et photo du colis).
  Future<Result<ActiveMission>> confirmPickup(String missionId, {required bool photoTaken, String? photoPath});

  /// Fin de course.
  Future<Result<MissionReceipt>> complete(String missionId);

  /// Remise d'une livraison : code du destinataire (6 chiffres) et photo de remise.
  Future<Result<MissionReceipt>> handover(
    String missionId, {
    required String code,
    required PaymentMode collectedWith,
    String? photoPath,
  });

  Future<Result<void>> rateCustomer(String missionId, int stars);

  /// Annulation par le chauffeur (course : en route, arrivé ou en pause ; livraison : avant la collecte).
  Future<Result<void>> cancel(String missionId, {String? reason});

  /// Client absent, après le délai d'attente.
  Future<Result<void>> declareNoShow(String missionId, {String? reason});

  /// Échec de collecte ou de remise d'une livraison (motif libre).
  Future<Result<ActiveMission>> reportFailure(String missionId, String reason);
  Future<Result<ActiveMission>> startReturn(String missionId);
  Future<Result<void>> completeReturn(String missionId);

  Stream<DestinationChange> destinationChanges();
  Future<Result<ActiveMission>> answerDestination(String missionId, {required bool accept, String? reason});

  /// Zone de forte demande la plus proche (texte prêt à afficher), `null` si aucune.
  Stream<String?> hotZones();

  Future<Result<DirectEstimate>> estimateDirect(DirectRideRequest request);
  Future<Result<ActiveMission>> startDirect(DirectRideRequest request);
}
