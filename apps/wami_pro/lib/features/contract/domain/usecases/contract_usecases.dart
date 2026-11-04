import 'package:wami_core/wami_core.dart';

import '../entities/contract.dart';
import '../repositories/contract_repository.dart';

class GetContract implements UseCase<VehicleContract?, NoParams> {
  const GetContract(this._repo);
  final ContractRepository _repo;

  @override
  Future<Result<VehicleContract?>> call(NoParams _) => _repo.getContract();
}
