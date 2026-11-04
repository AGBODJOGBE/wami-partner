import 'package:flutter_test/flutter_test.dart';
import 'package:wami_pro/features/missions/domain/entities/fare.dart';
import 'package:wami_pro/features/missions/domain/entities/mission.dart';

const _offer = MissionOffer(
  id: 'M1',
  kind: MissionKind.ride,
  pickup: Stop(label: 'A', address: ''),
  dropoff: Stop(label: 'B', address: ''),
  distanceToPickupKm: 1,
  tripKm: 5,
  tripMinutes: 10,
  clientPrice: 1700,
  netEarning: 1445,
  payment: PaymentMode.cash,
  customerName: 'X',
  customerRating: 4.8,
);

void main() {
  const policy = FarePolicy(freeWaitingSeconds: 120, waitingRatePerMinute: 50, pauseRatePerMinute: 25, commissionRate: 0.15);

  test('attente : gratuite puis chaque minute entamée', () {
    expect(policy.waitingFee(120), 0);
    expect(policy.waitingFee(121), 50);
    expect(policy.waitingFee(181), 100);
  });

  test('reçu : attente + pause + commission, payé en espèces', () {
    final t0 = DateTime(2026, 11, 4, 10);
    final m = ActiveMission(
      offer: _offer,
      stage: MissionStage.inProgress,
      arrivedAt: t0,
      startedAt: t0.add(const Duration(seconds: 160)), // 40 s facturées → 50 F
      pausedBefore: const Duration(seconds: 70), // 2 minutes entamées → 50 F
    );
    final r = MissionReceipt.compute(m, policy, t0.add(const Duration(minutes: 10)));
    expect(r.waitingFee, 50);
    expect(r.pauseFee, 50);
    expect(r.total, 1800);
    expect(r.commission, 270);
    expect(r.net, 1530);
    expect(r.commissionDueFromPartner, isTrue);
  });

  test('contact client possible seulement avant le démarrage', () {
    expect(MissionStage.atPickup.canContactCustomer, isTrue);
    expect(MissionStage.inProgress.canContactCustomer, isFalse);
  });
}
