import 'package:wami_core/wami_core.dart';

import '../entities/finances.dart';
import '../repositories/finances_repository.dart';

/// Versements automatiques : pas de retrait manuel côté établissement (à valider).
class GetFinanceOverview implements UseCase<FinanceOverview, String> {
  const GetFinanceOverview(this._repo);
  final FinancesRepository _repo;

  @override
  Future<Result<FinanceOverview>> call(String establishmentId) => _repo.getOverview(establishmentId);
}
