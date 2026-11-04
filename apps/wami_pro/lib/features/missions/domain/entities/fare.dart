import 'package:equatable/equatable.dart';

import 'mission.dart';

/// Règles de calcul du partenaire. Toutes les valeurs sont **à valider**
/// (elles viennent du serveur en production ; celles-ci sont des défauts).
class FarePolicy extends Equatable {
  const FarePolicy({
    this.freeWaitingSeconds = 120,
    this.waitingRatePerMinute = 50,
    this.pauseBilled = true,
    this.pauseRatePerMinute = 25,
    this.commissionRate = 0.15,
    this.noShowCancelSeconds = 300,
  });

  final int freeWaitingSeconds;
  final int waitingRatePerMinute;
  final bool pauseBilled;
  final int pauseRatePerMinute;

  /// Commission WAMI sur le montant payé par le client.
  final double commissionRate;

  /// Délai après lequel le chauffeur peut annuler pour client absent.
  final int noShowCancelSeconds;

  int freeLeft(int waited) => (freeWaitingSeconds - waited).clamp(0, freeWaitingSeconds);

  /// Chaque minute entamée au-delà de l'attente gratuite.
  int waitingFee(int waited) {
    final billable = waited - freeWaitingSeconds;
    return billable <= 0 ? 0 : ((billable + 59) ~/ 60) * waitingRatePerMinute;
  }

  int pauseFee(int paused) =>
      (!pauseBilled || paused <= 0) ? 0 : ((paused + 59) ~/ 60) * pauseRatePerMinute;

  int commission(int total) => (total * commissionRate).round();

  @override
  List<Object?> get props =>
      [freeWaitingSeconds, waitingRatePerMinute, pauseBilled, pauseRatePerMinute, commissionRate, noShowCancelSeconds];
}

/// Récapitulatif de fin de mission.
class MissionReceipt extends Equatable {
  const MissionReceipt({
    required this.kind,
    required this.clientPrice,
    required this.waitingFee,
    required this.pauseFee,
    required this.commission,
    required this.payment,
    this.cashCollected = 0,
  });

  /// Calcul à partir de la mission et des règles (le serveur reste la référence).
  factory MissionReceipt.compute(ActiveMission m, FarePolicy policy, DateTime now) {
    final waiting = policy.waitingFee(m.waitedSeconds(now));
    final pause = policy.pauseFee(m.pausedSeconds(now));
    final total = m.offer.clientPrice + waiting + pause;
    return MissionReceipt(
      kind: m.offer.kind,
      clientPrice: m.offer.clientPrice,
      waitingFee: waiting,
      pauseFee: pause,
      commission: policy.commission(total),
      payment: m.offer.payment,
      cashCollected: m.offer.cashToCollect,
    );
  }

  final MissionKind kind;
  final int clientPrice;
  final int waitingFee;
  final int pauseFee;
  final int commission;
  final PaymentMode payment;

  /// Somme encaissée pour l'expéditeur (reversée par WAMI).
  final int cashCollected;

  int get total => clientPrice + waitingFee + pauseFee;
  int get net => total - commission;

  /// Payé en espèces : le partenaire garde l'argent, la commission est due à WAMI.
  bool get commissionDueFromPartner => payment == PaymentMode.cash;

  @override
  List<Object?> get props => [kind, clientPrice, waitingFee, pauseFee, commission, payment, cashCollected];
}

/// Liste de contrôle à la collecte d'une livraison.
abstract final class PickupChecklist {
  static List<String> itemsFor(MissionOffer o) => switch (o.kind) {
        MissionKind.parcel => [
            'La taille correspond (${o.parcelSize ?? '—'})',
            'Colis fermé, sans dégât visible',
          ],
        MissionKind.meal => ['Sac fermé par le restaurant', 'Nombre d’articles vérifié'],
        MissionKind.ride => const [],
      };

  /// Photo obligatoire pour un colis (preuve en cas de litige).
  static bool photoRequired(MissionOffer o) => o.kind == MissionKind.parcel;
}
