import 'package:wami_core/wami_core.dart';

import '../../domain/entities/history.dart';

abstract interface class HistoryRemoteDataSource {
  Future<List<HistoryRide>> rides();
  Future<List<HistoryDelivery>> deliveries();
}

int _int(Object? v) => v is num ? v.round() : 0;
DateTime _date(Object? v) => DateTime.tryParse('$v')?.toLocal() ?? DateTime.now();
String _addr(Object? j, String fallback) {
  final a = j is Map ? (j['address'] as String?)?.trim() : null;
  return (a == null || a.isEmpty) ? fallback : a;
}

(HistoryOutcome, String) _rideStatus(String s) => switch (s) {
      'COMPLETED' || 'RATED' => (HistoryOutcome.done, 'Terminée'),
      'CANCELLED_PASSENGER' => (HistoryOutcome.cancelled, 'Annulée par le client'),
      'CANCELLED_DRIVER' => (HistoryOutcome.cancelled, 'Annulée par vous'),
      'CANCELLED_SYSTEM' => (HistoryOutcome.cancelled, 'Annulée par WAMI'),
      'NO_SHOW_PASSENGER' => (HistoryOutcome.cancelled, 'Client absent'),
      'DISPUTED' => (HistoryOutcome.failed, 'Litige'),
      'NO_DRIVER_FOUND' => (HistoryOutcome.failed, 'Sans chauffeur'),
      _ => (HistoryOutcome.inProgress, 'En cours'),
    };

(HistoryOutcome, String) _deliveryStatus(String s) => switch (s) {
      'COMPLETED' => (HistoryOutcome.done, 'Livrée'),
      'RETURNED' => (HistoryOutcome.failed, 'Colis rendu'),
      'CANCELLED' => (HistoryOutcome.cancelled, 'Annulée'),
      'PICKUP_FAILED' => (HistoryOutcome.failed, 'Collecte échouée'),
      'DELIVERY_FAILED' => (HistoryOutcome.failed, 'Remise échouée'),
      _ => (HistoryOutcome.inProgress, 'En cours'),
    };

/// `GET /api/drivers/rides` ({rides, total}) et `GET /api/driver/delivery` (tableau direct).
class HistoryApiDataSource implements HistoryRemoteDataSource {
  const HistoryApiDataSource(this._api);
  final ApiClient _api;

  @override
  Future<List<HistoryRide>> rides() async {
    final j = await _api.get('/api/drivers/rides');
    return ((j['rides'] as List<dynamic>?) ?? const []).cast<Map<String, dynamic>>().map((r) {
      final (outcome, label) = _rideStatus('${r['status']}');
      final p = r['passenger'] is Map ? r['passenger'] as Map : const {};
      return HistoryRide(
        id: '${r['rideId']}',
        number: '${r['rideNumber'] ?? ''}',
        outcome: outcome,
        statusLabel: label,
        date: _date(r['completedAt'] ?? r['cancelledAt'] ?? r['createdAt']),
        pickup: _addr(r['pickup'], 'Départ'),
        dropoff: _addr(r['dropoff'], 'Arrivée'),
        price: _int(r['finalPrice'] ?? r['estimatedPrice']),
        earnings: r['driverEarnings'] is num ? _int(r['driverEarnings']) : null,
        passenger: '${p['firstName'] ?? ''} ${p['lastName'] ?? ''}'.trim(),
        rating: r['passengerRating'] is num ? _int(r['passengerRating']) : null,
      );
    }).toList();
  }

  @override
  Future<List<HistoryDelivery>> deliveries() async {
    final j = await _api.get('/api/driver/delivery');
    return ((j['items'] as List<dynamic>?) ?? const []).cast<Map<String, dynamic>>().map((d) {
      final (outcome, label) = _deliveryStatus('${d['status']}');
      return HistoryDelivery(
        id: '${d['id']}',
        number: '${d['orderNumber'] ?? ''}',
        outcome: outcome,
        statusLabel: label,
        date: _date(d['updatedAt'] ?? d['createdAt']),
        pickup: _addr(d['pickup'], 'Collecte'),
        dropoff: _addr(d['dropoff'], 'Livraison'),
        price: _int(d['finalPrice'] ?? d['estimatedPrice']),
        cancelReason: d['cancelReason'] as String?,
      );
    }).toList();
  }
}

class HistoryFakeDataSource implements HistoryRemoteDataSource {
  HistoryFakeDataSource(this._fake);
  final FakeBackend _fake;

  @override
  Future<List<HistoryRide>> rides() async {
    await _fake.latency(0.5);
    final now = DateTime.now();
    return [
      HistoryRide(id: 'r1', number: 'R-1042', outcome: HistoryOutcome.done, statusLabel: 'Terminée', date: now.subtract(const Duration(hours: 2)), pickup: 'Marché Dantokpa', dropoff: 'Fidjrossè', price: 1700, earnings: 1445, passenger: 'Client', rating: 5),
      HistoryRide(id: 'r2', number: 'R-1040', outcome: HistoryOutcome.cancelled, statusLabel: 'Client absent', date: now.subtract(const Duration(days: 1)), pickup: 'Cadjèhoun', dropoff: 'Akpakpa', price: 1200, earnings: null, passenger: 'Client'),
    ];
  }

  @override
  Future<List<HistoryDelivery>> deliveries() async {
    await _fake.latency(0.5);
    return [
      HistoryDelivery(id: 'd1', number: 'WM-B2C-A1', outcome: HistoryOutcome.done, statusLabel: 'Livrée', date: DateTime.now().subtract(const Duration(days: 1)), pickup: 'Cadjèhoun', dropoff: 'Akpakpa', price: 1000),
    ];
  }
}
