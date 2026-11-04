import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wami_core/wami_core.dart';
import 'package:wami_pro/features/missions/domain/entities/fare.dart';
import 'package:wami_pro/features/missions/domain/entities/mission.dart';
import 'package:wami_pro/features/missions/domain/repositories/missions_repository.dart';
import 'package:wami_pro/features/missions/domain/usecases/missions_usecases.dart';

class _Repo extends Mock implements MissionsRepository {}

const _parcel = MissionOffer(
  id: 'P1',
  kind: MissionKind.parcel,
  pickup: Stop(label: 'A', address: ''),
  dropoff: Stop(label: 'B', address: ''),
  distanceToPickupKm: 1,
  tripKm: 5,
  tripMinutes: 10,
  clientPrice: 1000,
  netEarning: 850,
  payment: PaymentMode.wallet,
  customerName: 'X',
  customerRating: 4.7,
  parcelSize: 'moyen',
);

void main() {
  late _Repo repo;
  setUpAll(() => registerFallbackValue(PaymentMode.cash));
  setUp(() => repo = _Repo());

  test('la course démarre sans code du client (le serveur n’en demande pas)', () async {
    when(() => repo.start('M1', ''))
        .thenAnswer((_) async => const Ok(ActiveMission(offer: _parcel, stage: MissionStage.inProgress)));
    final r = await StartTrip(repo)(const StartParams(missionId: 'M1'));
    expect(r.isOk, isTrue);
  });

  test('la remise exige le code à 6 chiffres du destinataire', () async {
    final r = await ConfirmHandover(repo)(const HandoverParams(
      missionId: 'P1',
      code: '4821',
      collectedWith: PaymentMode.cash,
      photoPath: '/tmp/photo.jpg',
    ));
    expect((r as Err<MissionReceipt>).failure, isA<ValidationFailure>());
    verifyNever(() => repo.handover(any(), code: any(named: 'code'), collectedWith: any(named: 'collectedWith')));
  });

  test('collecte refusée sans photo pour un colis', () async {
    const m = ActiveMission(offer: _parcel, stage: MissionStage.atPickup);
    final r = await ConfirmPickup(repo)(const PickupParams(
      mission: m,
      checked: {'La taille correspond (moyen)', 'Colis fermé, sans dégât visible'},
      photoTaken: false,
    ));
    expect((r as Err<ActiveMission>).failure, isA<ValidationFailure>());
  });

  test('collecte acceptée quand tout est coché et la photo prise', () async {
    const m = ActiveMission(offer: _parcel, stage: MissionStage.atPickup);
    when(() => repo.confirmPickup('P1', photoTaken: true, photoPath: '/tmp/colis.jpg'))
        .thenAnswer((_) async => const Ok(ActiveMission(offer: _parcel, stage: MissionStage.inProgress)));
    final r = await ConfirmPickup(repo)(const PickupParams(
      mission: m,
      checked: {'La taille correspond (moyen)', 'Colis fermé, sans dégât visible'},
      photoTaken: true,
      photoPath: '/tmp/colis.jpg',
    ));
    expect(r.valueOrNull?.stage, MissionStage.inProgress);
  });
}
