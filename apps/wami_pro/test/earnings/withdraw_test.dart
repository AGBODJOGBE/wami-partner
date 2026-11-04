import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wami_core/wami_core.dart';
import 'package:wami_pro/features/earnings/domain/entities/earnings.dart';
import 'package:wami_pro/features/earnings/domain/repositories/earnings_repository.dart';
import 'package:wami_pro/features/earnings/domain/usecases/earnings_usecases.dart';

class _Repo extends Mock implements EarningsRepository {}

void main() {
  const wallet = PartnerWallet(
    available: 10000,
    cashCommissionDue: 3000,
    payoutMethod: 'MoMo',
    payoutSchedule: '',
    movements: [],
  );

  test('le disponible tient compte de la commission due sur les espèces', () {
    expect(wallet.withdrawable, 7000);
  });

  test('retrait refusé au-delà du disponible', () async {
    final repo = _Repo();
    final r = await WithdrawEarnings(repo)(const WithdrawParams(wallet: wallet, amount: 8000));
    expect((r as Err<PartnerWallet>).failure, isA<InsufficientFundsFailure>());
    verifyNever(() => repo.withdraw(any()));
  });
}
