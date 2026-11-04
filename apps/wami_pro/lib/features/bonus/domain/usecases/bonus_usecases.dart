import 'package:wami_core/wami_core.dart';

import '../entities/bonus.dart';
import '../repositories/bonus_repository.dart';

class GetBonusOverview implements UseCase<BonusOverview, NoParams> {
  const GetBonusOverview(this._repo);
  final BonusRepository _repo;

  @override
  Future<Result<BonusOverview>> call(NoParams _) => _repo.getOverview();
}

class ConsolidateBonus implements UseCase<void, int> {
  const ConsolidateBonus(this._repo);
  final BonusRepository _repo;

  /// Minimum par défaut du serveur (modifiable par l'administration, qui reste juge).
  static const minimum = 500;

  @override
  Future<Result<void>> call(int amount) async {
    if (amount < minimum) return Err(ValidationFailure('Transfert minimum : ${Fmt.fcfa(minimum)}.'));
    return _repo.consolidateBonus(amount);
  }
}
