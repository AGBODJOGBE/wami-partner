import '../../domain/entities/fare.dart';
import '../../domain/entities/mission.dart';

/// Conversions JSON ↔ entités. Format à valider avec l'équipe back.
abstract final class MissionModels {
  static DriverDay day(Map<String, dynamic> j) => DriverDay(
        online: j['online'] as bool,
        onlineSince: DateTime.tryParse(j['online_since'] as String? ?? ''),
        earnings: j['earnings'] as int,
        missions: j['missions'] as int,
        rating: (j['rating'] as num).toDouble(),
        acceptanceRate: (j['acceptance_rate'] as num).toDouble(),
        hotZone: j['hot_zone'] as String?,
      );

  static FarePolicy policy(Map<String, dynamic> j) => FarePolicy(
        freeWaitingSeconds: j['free_waiting_seconds'] as int,
        waitingRatePerMinute: j['waiting_rate_per_minute'] as int,
        pauseBilled: j['pause_billed'] as bool,
        pauseRatePerMinute: j['pause_rate_per_minute'] as int,
        commissionRate: (j['commission_rate'] as num).toDouble(),
        noShowCancelSeconds: j['no_show_cancel_seconds'] as int? ?? 300,
      );

  static Stop stop(Map<String, dynamic> j) => Stop(
        label: j['label'] as String,
        address: j['address'] as String? ?? '',
        contactName: j['contact_name'] as String?,
        note: j['note'] as String?,
      );

  static MissionOffer offer(Map<String, dynamic> j) => MissionOffer(
        id: j['id'] as String,
        kind: MissionKind.values.byName(j['kind'] as String),
        pickup: stop(j['pickup'] as Map<String, dynamic>),
        dropoff: stop(j['dropoff'] as Map<String, dynamic>),
        distanceToPickupKm: (j['distance_to_pickup_km'] as num).toDouble(),
        tripKm: (j['trip_km'] as num).toDouble(),
        tripMinutes: j['trip_minutes'] as int,
        clientPrice: j['client_price'] as int,
        netEarning: j['net_earning'] as int,
        payment: PaymentMode.values.byName(j['payment'] as String),
        customerName: j['customer_name'] as String,
        customerRating: (j['customer_rating'] as num).toDouble(),
        cashToCollect: j['cash_to_collect'] as int? ?? 0,
        parcelSize: j['parcel_size'] as String?,
        fragile: j['fragile'] as bool? ?? false,
        orderNumber: j['order_number'] as String?,
        items: (j['items'] as List<dynamic>? ?? const []).cast<String>(),
        acceptSeconds: j['accept_seconds'] as int? ?? 15,
      );

  static ActiveMission active(Map<String, dynamic> j) => ActiveMission(
        offer: offer(j['offer'] as Map<String, dynamic>),
        stage: MissionStage.values.byName(j['stage'] as String),
        arrivedAt: DateTime.tryParse(j['arrived_at'] as String? ?? ''),
        startedAt: DateTime.tryParse(j['started_at'] as String? ?? ''),
        pausedAt: DateTime.tryParse(j['paused_at'] as String? ?? ''),
        pausedBefore: Duration(seconds: j['paused_seconds'] as int? ?? 0),
      );

  static MissionReceipt receipt(Map<String, dynamic> j) => MissionReceipt(
        kind: MissionKind.values.byName(j['kind'] as String),
        clientPrice: j['client_price'] as int,
        waitingFee: j['waiting_fee'] as int? ?? 0,
        pauseFee: j['pause_fee'] as int? ?? 0,
        commission: j['commission'] as int,
        payment: PaymentMode.values.byName(j['payment'] as String),
        cashCollected: j['cash_collected'] as int? ?? 0,
      );
}
