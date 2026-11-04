import 'package:wami_core/wami_core.dart';

import '../../domain/entities/contract.dart';
import '../../domain/repositories/contract_repository.dart';
import '../datasources/contract_data_sources.dart';

class ContractRepositoryImpl implements ContractRepository {
  const ContractRepositoryImpl(this._remote);
  final ContractRemoteDataSource _remote;

  @override
  Future<Result<VehicleContract?>> getContract() => guard(_remote.contract);
}
