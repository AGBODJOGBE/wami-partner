import 'package:wami_core/wami_core.dart';

import '../entities/earnings.dart';
import '../repositories/earnings_repository.dart';

class GetEarnings implements UseCase<EarningsSummary, EarningsPeriod> {
  const GetEarnings(this._repo);
  final EarningsRepository _repo;

  @override
  Future<Result<EarningsSummary>> call(EarningsPeriod p) => _repo.getEarnings(p);
}

class GetPartnerWallet implements UseCase<PartnerWallet, NoParams> {
  const GetPartnerWallet(this._repo);
  final EarningsRepository _repo;

  @override
  Future<Result<PartnerWallet>> call(NoParams _) => _repo.getWallet();
}

class WithdrawParams {
  const WithdrawParams({required this.wallet, required this.amount});
  final PartnerWallet wallet;
  final int amount;
}

/// Règle : on ne retire que le disponible, commission espèces déduite.
/// Minimum de retrait et frais : à valider.
class WithdrawEarnings implements UseCase<PartnerWallet, WithdrawParams> {
  const WithdrawEarnings(this._repo);
  final EarningsRepository _repo;

  static const minimum = 1000;

  @override
  Future<Result<PartnerWallet>> call(WithdrawParams p) async {
    if (p.amount < minimum) return Err(ValidationFailure('Retrait minimum : ${Fmt.fcfa(minimum)}.'));
    if (p.amount > p.wallet.withdrawable) return const Err(InsufficientFundsFailure('Montant supérieur au disponible.'));
    return _repo.withdraw(p.amount);
  }
}

class GetPerformance implements UseCase<Performance, NoParams> {
  const GetPerformance(this._repo);
  final EarningsRepository _repo;

  @override
  Future<Result<Performance>> call(NoParams _) => _repo.getPerformance();
}
