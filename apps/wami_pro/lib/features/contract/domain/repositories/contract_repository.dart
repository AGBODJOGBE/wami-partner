import 'package:wami_core/wami_core.dart';

import '../entities/contract.dart';

abstract interface class ContractRepository {
  /// `null` quand le partenaire n'a aucun contrat.
  Future<Result<VehicleContract?>> getContract();
}
