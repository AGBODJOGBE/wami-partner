import 'package:wami_core/wami_core.dart';

import '../../domain/entities/finances.dart';
import '../../domain/repositories/finances_repository.dart';
import '../datasources/finances_data_sources.dart';

class FinancesRepositoryImpl implements FinancesRepository {
  const FinancesRepositoryImpl(this._remote);
  final FinancesRemoteDataSource _remote;

  @override
  Future<Result<FinanceOverview>> getOverview(String establishmentId) => guard(() => _remote.overview(establishmentId));
}
