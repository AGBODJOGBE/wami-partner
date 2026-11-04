import 'package:wami_core/wami_core.dart';

import '../entities/finances.dart';

abstract interface class FinancesRepository {
  Future<Result<FinanceOverview>> getOverview(String establishmentId);
}
