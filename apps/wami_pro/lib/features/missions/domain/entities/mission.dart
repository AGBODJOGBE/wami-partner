import 'package:equatable/equatable.dart';

enum MissionKind {
  ride('Course'),
  parcel('Colis'),
  meal('Repas');

  const MissionKind(this.label);
  final String label;

  bool get isDelivery => this != ride;
}

enum PaymentMode {
  wallet('Portefeuille'),
  cash('Espèces'),
  mobileMoney('Mobile Money');

  const PaymentMode(this.label);
  final String label;
}

class Stop extends Equatable {
  const Stop({required this.label, required this.address, this.contactName, this.contactPhone, this.note});
  final String label;
  final String address;
  final String? contactName;

  /// Numéro à appeler (client pour une course, expéditeur ou destinataire pour une livraison).
  final String? contactPhone;
  final String? note;

  @override
  List<Object?> get props => [label, address, contactName, contactPhone, note];
}

/// Mission proposée au partenaire, à accepter dans le délai imparti.
class MissionOffer extends Equatable {
  const MissionOffer({
    required this.id,
    required this.kind,
    required this.pickup,
    required this.dropoff,
    required this.distanceToPickupKm,
    required this.tripKm,
    required this.tripMinutes,
    required this.clientPrice,
    required this.netEarning,
    required this.payment,
    required this.customerName,
    required this.customerRating,
    this.cashToCollect = 0,
    this.parcelSize,
    this.fragile = false,
    this.orderNumber,
    this.items = const [],
    this.acceptSeconds = 15,
  });

  final String id;
  final MissionKind kind;
  final Stop pickup;
  final Stop dropoff;
  final double distanceToPickupKm;
  final double tripKm;
  final int tripMinutes;

  /// Prix payé par le client (hors attente et pause).
  final int clientPrice;

  /// Gain net estimé du partenaire.
  final int netEarning;
  final PaymentMode payment;
  final String customerName;
  final double customerRating;

  /// Montant à encaisser au destinataire (colis contre remboursement).
  final int cashToCollect;
  final String? parcelSize;
  final bool fragile;

  /// Numéro de commande (repas).
  final String? orderNumber;
  final List<String> items;

  /// Délai pour accepter (à valider : 15 s proposé).
  final int acceptSeconds;

  MissionOffer copyWith({
    Stop? pickup,
    Stop? dropoff,
    String? customerName,
    String? parcelSize,
    bool? fragile,
  }) {
    return MissionOffer(
      id: id,
      kind: kind,
      pickup: pickup ?? this.pickup,
      dropoff: dropoff ?? this.dropoff,
      distanceToPickupKm: distanceToPickupKm,
      tripKm: tripKm,
      tripMinutes: tripMinutes,
      clientPrice: clientPrice,
      netEarning: netEarning,
      payment: payment,
      customerName: customerName ?? this.customerName,
      customerRating: customerRating,
      cashToCollect: cashToCollect,
      parcelSize: parcelSize ?? this.parcelSize,
      fragile: fragile ?? this.fragile,
      orderNumber: orderNumber,
      items: items,
      acceptSeconds: acceptSeconds,
    );
  }

  @override
  List<Object?> get props => [
        id, kind, pickup, dropoff, distanceToPickupKm, tripKm, tripMinutes, clientPrice, netEarning,
        payment, customerName, customerRating, cashToCollect, parcelSize, fragile, orderNumber, items, acceptSeconds,
      ];
}

enum MissionStage {
  /// En route vers le point de prise en charge.
  toPickup,

  /// Sur place : attente du client (course) ou collecte (livraison).
  atPickup,

  /// Course démarrée ou colis en route.
  inProgress,

  /// Course en pause (course uniquement).
  paused,

  completed,
  cancelled;

  /// Contact (appel, message) avant le démarrage seulement, comme côté client.
  bool get canContactCustomer => this == toPickup || this == atPickup;
}

/// Mission acceptée, avec les horodatages qui servent au calcul de l'attente et de la pause.
class ActiveMission extends Equatable {
  const ActiveMission({
    required this.offer,
    required this.stage,
    this.arrivedAt,
    this.startedAt,
    this.pausedAt,
    this.pausedBefore = Duration.zero,
  });

  final MissionOffer offer;
  final MissionStage stage;
  final DateTime? arrivedAt;
  final DateTime? startedAt;

  /// Début de la pause en cours.
  final DateTime? pausedAt;

  /// Cumul des pauses terminées.
  final Duration pausedBefore;

  /// Attente au point de départ : de l'arrivée au démarrage.
  int waitedSeconds(DateTime now) {
    final from = arrivedAt;
    if (from == null || offer.kind.isDelivery) return 0;
    final to = startedAt ?? now;
    return to.difference(from).inSeconds.clamp(0, 1 << 30);
  }

  int pausedSeconds(DateTime now) {
    final running = pausedAt == null ? Duration.zero : now.difference(pausedAt!);
    return (pausedBefore + running).inSeconds;
  }

  /// Avancement estimé (en production : position GPS sur l'itinéraire).
  double progress(DateTime now) {
    final s = startedAt;
    if (s == null) return 0;
    final riding = now.difference(s).inSeconds - pausedSeconds(now);
    final total = offer.tripMinutes * 60;
    return total <= 0 ? 1 : (riding / total).clamp(0.0, 1.0);
  }

  ActiveMission copyWith({
    MissionStage? stage,
    DateTime? arrivedAt,
    DateTime? startedAt,
    DateTime? pausedAt,
    bool clearPausedAt = false,
    Duration? pausedBefore,
  }) {
    return ActiveMission(
      offer: offer,
      stage: stage ?? this.stage,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      startedAt: startedAt ?? this.startedAt,
      pausedAt: clearPausedAt ? null : (pausedAt ?? this.pausedAt),
      pausedBefore: pausedBefore ?? this.pausedBefore,
    );
  }

  @override
  List<Object?> get props => [offer, stage, arrivedAt, startedAt, pausedAt, pausedBefore];
}

/// Journée du partenaire.
class DriverDay extends Equatable {
  const DriverDay({
    required this.online,
    required this.earnings,
    required this.missions,
    required this.rating,
    required this.acceptanceRate,
    this.onlineSince,
    this.hotZone,
  });

  final bool online;
  final DateTime? onlineSince;
  final int earnings;
  final int missions;
  final double rating;
  final double acceptanceRate;

  /// Zone de forte demande signalée (bonus de zone à valider).
  final String? hotZone;

  DriverDay copyWith({bool? online, DateTime? onlineSince, int? earnings, int? missions}) => DriverDay(
        online: online ?? this.online,
        onlineSince: onlineSince ?? this.onlineSince,
        earnings: earnings ?? this.earnings,
        missions: missions ?? this.missions,
        rating: rating,
        acceptanceRate: acceptanceRate,
        hotZone: hotZone,
      );

  @override
  List<Object?> get props => [online, onlineSince, earnings, missions, rating, acceptanceRate, hotZone];
}
