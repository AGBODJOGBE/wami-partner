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

class TransferParams {
  const TransferParams({required this.wallet, required this.phone, required this.amount, this.note});
  final PartnerWallet wallet;
  final String phone;
  final int amount;
  final String? note;
}

/// Seul le solde principal peut être envoyé (pas le bonus). Le minimum exact est fixé par le serveur.
class TransferMoney implements UseCase<TransferReceipt, TransferParams> {
  const TransferMoney(this._repo);
  final EarningsRepository _repo;

  @override
  Future<Result<TransferReceipt>> call(TransferParams p) async {
    final digits = p.phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8 && !(digits.length == 10 && digits.startsWith('01'))) {
      return const Err(ValidationFailure('Numéro invalide : 10 chiffres commençant par 01.'));
    }
    if (p.amount <= 0) return const Err(ValidationFailure('Indiquez un montant.'));
    if (p.amount > p.wallet.available) return const Err(InsufficientFundsFailure('Montant supérieur à votre solde.'));
    return _repo.transfer(phone: digits, amount: p.amount, note: p.note);
  }
}
