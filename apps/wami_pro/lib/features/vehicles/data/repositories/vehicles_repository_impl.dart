import 'package:wami_core/wami_core.dart';

import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/vehicles_repository.dart';
import '../datasources/vehicles_data_sources.dart';

class VehiclesRepositoryImpl implements VehiclesRepository {
  const VehiclesRepositoryImpl(this._remote);
  final VehiclesRemoteDataSource _remote;

  @override
  Future<Result<List<VehicleItem>>> list() => guard(_remote.list);

  @override
  Future<Result<void>> add(NewVehicle v) => guard(() => _remote.add(v));

  @override
  Future<Result<void>> setActive(String vehicleId) => guard(() => _remote.setActive(vehicleId));

  @override
  Future<Result<void>> setCategories(String vehicleId, List<VehicleCategory> categories) =>
      guard(() => _remote.setCategories(vehicleId, categories));

  @override
  Future<Result<String>> requestUpgrade(String vehicleId, VehicleCategory category, String? reason) =>
      guard(() => _remote.requestUpgrade(vehicleId, category, reason));

  @override
  Future<Result<void>> delete(String vehicleId) => guard(() => _remote.delete(vehicleId));
}
