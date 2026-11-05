import 'package:wami_core/wami_core.dart';

import '../entities/vehicle.dart';
import '../repositories/vehicles_repository.dart';

class ListVehicles implements UseCase<List<VehicleItem>, NoParams> {
  const ListVehicles(this._repo);
  final VehiclesRepository _repo;

  @override
  Future<Result<List<VehicleItem>>> call(NoParams _) => _repo.list();
}

class AddVehicle implements UseCase<void, NewVehicle> {
  const AddVehicle(this._repo);
  final VehiclesRepository _repo;

  @override
  Future<Result<void>> call(NewVehicle v) async {
    final (min, max) = v.kind.seatRange;
    if (v.make.trim().isEmpty || v.model.trim().isEmpty || v.color.trim().isEmpty || v.plate.trim().isEmpty) {
      return const Err(ValidationFailure('Renseignez la marque, le modèle, la couleur et la plaque.'));
    }
    final now = DateTime.now().year;
    if (v.year < 2000 || v.year > now + 1) return Err(ValidationFailure('Année entre 2000 et ${now + 1}.'));
    if (v.seats < min || v.seats > max) return Err(ValidationFailure('Places : de $min à $max pour ${v.kind.label.toLowerCase()}.'));
    if (v.insuranceExpiry != null && v.insuranceExpiry!.isBefore(DateTime.now())) {
      return const Err(ValidationFailure('L’assurance est expirée.'));
    }
    return _repo.add(v);
  }
}

class SetActiveVehicle implements UseCase<void, String> {
  const SetActiveVehicle(this._repo);
  final VehiclesRepository _repo;

  @override
  Future<Result<void>> call(String id) => _repo.setActive(id);
}

class CategoriesParams {
  const CategoriesParams(this.vehicleId, this.categories);
  final String vehicleId;
  final List<VehicleCategory> categories;
}

class SetVehicleCategories implements UseCase<void, CategoriesParams> {
  const SetVehicleCategories(this._repo);
  final VehiclesRepository _repo;

  @override
  Future<Result<void>> call(CategoriesParams p) async {
    if (p.categories.isEmpty) return const Err(ValidationFailure('Gardez au moins une catégorie.'));
    return _repo.setCategories(p.vehicleId, p.categories);
  }
}

class UpgradeParams {
  const UpgradeParams(this.vehicleId, this.category, this.reason);
  final String vehicleId;
  final VehicleCategory category;
  final String? reason;
}

class RequestCategoryUpgrade implements UseCase<String, UpgradeParams> {
  const RequestCategoryUpgrade(this._repo);
  final VehiclesRepository _repo;

  @override
  Future<Result<String>> call(UpgradeParams p) => _repo.requestUpgrade(p.vehicleId, p.category, p.reason);
}

class DeleteVehicle implements UseCase<void, String> {
  const DeleteVehicle(this._repo);
  final VehiclesRepository _repo;

  @override
  Future<Result<void>> call(String id) => _repo.delete(id);
}
