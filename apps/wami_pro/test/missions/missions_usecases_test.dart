import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wami_core/wami_core.dart';
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
  setUp(() => repo = _Repo());

  test('la course ne démarre pas sans code à 4 chiffres', () async {
    final r = await StartTrip(repo)(const StartParams(missionId: 'M1', code: '12'));
    expect(r.isOk, isFalse);
    verifyNever(() => repo.start(any(), any()));
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
    when(() => repo.confirmPickup('P1', photoTaken: true))
        .thenAnswer((_) async => const Ok(ActiveMission(offer: _parcel, stage: MissionStage.inProgress)));
    final r = await ConfirmPickup(repo)(const PickupParams(
      mission: m,
      checked: {'La taille correspond (moyen)', 'Colis fermé, sans dégât visible'},
      photoTaken: true,
    ));
    expect(r.valueOrNull?.stage, MissionStage.inProgress);
  });
}
