import 'package:wami_core/wami_core.dart';

import '../entities/earnings.dart';

abstract interface class EarningsRepository {
  Future<Result<EarningsSummary>> getEarnings(EarningsPeriod period);
  Future<Result<PartnerWallet>> getWallet();
  Future<Result<PartnerWallet>> withdraw(int amount);
  Future<Result<Performance>> getPerformance();
}
