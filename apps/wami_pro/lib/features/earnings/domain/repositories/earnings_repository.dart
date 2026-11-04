import 'package:wami_core/wami_core.dart';

import '../entities/earnings.dart';

abstract interface class EarningsRepository {
  Future<Result<EarningsSummary>> getEarnings(EarningsPeriod period);
  Future<Result<PartnerWallet>> getWallet();
  Future<Result<PartnerWallet>> withdraw(int amount);
  Future<Result<Performance>> getPerformance();

  /// Envoi d'argent vers un autre portefeuille WAMI (frais retenus par le serveur).
  Future<Result<TransferReceipt>> transfer({required String phone, required int amount, String? note});
}
