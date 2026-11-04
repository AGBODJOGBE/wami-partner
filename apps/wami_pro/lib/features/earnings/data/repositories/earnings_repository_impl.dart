import 'package:wami_core/wami_core.dart';

import '../../domain/entities/earnings.dart';
import '../../domain/repositories/earnings_repository.dart';
import '../datasources/earnings_data_sources.dart';

class EarningsRepositoryImpl implements EarningsRepository {
  const EarningsRepositoryImpl(this._remote);
  final EarningsRemoteDataSource _remote;

  @override
  Future<Result<EarningsSummary>> getEarnings(EarningsPeriod period) => guard(() => _remote.earnings(period));

  @override
  Future<Result<PartnerWallet>> getWallet() => guard(_remote.wallet);

  @override
  Future<Result<PartnerWallet>> withdraw(int amount) => guard(() => _remote.withdraw(amount));

  @override
  Future<Result<Performance>> getPerformance() => guard(_remote.performance);
}
