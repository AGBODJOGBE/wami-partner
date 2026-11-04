import 'package:wami_core/wami_core.dart';

import '../entities/bonus.dart';

abstract interface class BonusRepository {
  Future<Result<BonusOverview>> getOverview();

  /// Transfère un solde de bonus vers le solde principal (frais retenus par le serveur).
  Future<Result<void>> consolidateBonus(int amount);
}
