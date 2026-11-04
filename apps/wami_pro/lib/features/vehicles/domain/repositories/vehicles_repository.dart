import 'package:wami_core/wami_core.dart';

import '../entities/vehicle.dart';

abstract interface class VehiclesRepository {
  Future<Result<List<VehicleItem>>> list();
  Future<Result<void>> add(NewVehicle v);
  Future<Result<void>> setActive(String vehicleId);
  Future<Result<void>> setCategories(String vehicleId, List<VehicleCategory> categories);

  /// Demande de passage à une catégorie supérieure. Le serveur n'enregistre rien pour l'instant
  /// (simple accusé de réception) : l'écran le dit au chauffeur.
  Future<Result<String>> requestUpgrade(String vehicleId, VehicleCategory category, String? reason);
  Future<Result<void>> delete(String vehicleId);
}
