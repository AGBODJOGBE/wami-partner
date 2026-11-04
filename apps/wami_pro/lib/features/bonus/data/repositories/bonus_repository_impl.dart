import 'package:wami_core/wami_core.dart';

import '../../domain/entities/bonus.dart';
import '../../domain/repositories/bonus_repository.dart';
import '../datasources/bonus_data_sources.dart';

class BonusRepositoryImpl implements BonusRepository {
  const BonusRepositoryImpl(this._remote);
  final BonusRemoteDataSource _remote;

  @override
  Future<Result<BonusOverview>> getOverview() => guard(_remote.overview);

  @override
  Future<Result<void>> consolidateBonus(int amount) => guard(() => _remote.consolidate(amount));
}
