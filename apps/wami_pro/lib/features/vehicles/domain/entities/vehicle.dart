import 'package:equatable/equatable.dart';

enum VehicleKind {
  moto('Moto', 'MOTO'),
  tricycle('Tricycle', 'TRICYCLE'),
  car('Voiture', 'CAR');

  const VehicleKind(this.label, this.api);
  final String label;
  final String api;

  static VehicleKind fromApi(Object? v) => values.firstWhere((k) => k.api == v, orElse: () => VehicleKind.car);

  /// Places autorisées par le serveur : moto 1-2, tricycle 2-4, voiture 2 et plus.
  (int, int) get seatRange => switch (this) {
        VehicleKind.moto => (1, 2),
        VehicleKind.tricycle => (2, 4),
        VehicleKind.car => (2, 8),
      };
}

/// Catégories de service d'une voiture. `premium` s'appelle « Confort » côté courses.
enum VehicleCategory {
  eco('Éco', 'ECO'),
  standard('Standard', 'STANDARD'),
  premium('Confort', 'PREMIUM'),
  vip('VIP', 'VIP');

  const VehicleCategory(this.label, this.api);
  final String label;
  final String api;

  static VehicleCategory? fromApi(Object? v) {
    for (final c in values) {
      if (c.api == v) return c;
    }
    return null;
  }
}

class VehicleItem extends Equatable {
  const VehicleItem({
    required this.id,
    required this.kind,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.plate,
    required this.seats,
    required this.status,
    required this.isVerified,
    required this.isActive,
    required this.activeCategories,
    required this.selectableCategories,
    this.category,
    this.insuranceExpiry,
  });

  final String id;
  final VehicleKind kind;
  final String make;
  final String model;
  final int year;
  final String color;
  final String plate;
  final int seats;

  /// `PENDING`, `AVAILABLE`, `ASSIGNED`, `EN_CONTRAT`, `MAINTENANCE`, `REJECTED`, `RETIRED`, `SOLD`.
  final String status;
  final bool isVerified;
  final bool isActive;
  final VehicleCategory? category;
  final List<VehicleCategory> activeCategories;

  /// Catégories que le chauffeur peut cocher (vide pour moto et tricycle).
  final List<VehicleCategory> selectableCategories;
  final DateTime? insuranceExpiry;

  String get title => '$make $model'.trim();

  String get statusLabel => switch (status) {
        'PENDING' => 'En vérification',
        'REJECTED' => 'Refusé',
        'MAINTENANCE' => 'En maintenance',
        'RETIRED' => 'Retiré',
        'SOLD' => 'Vendu',
        'EN_CONTRAT' => 'Sous contrat',
        _ => isVerified ? 'Vérifié' : 'À vérifier',
      };

  /// Un véhicule peut être supprimé s'il n'est ni assigné ni sous contrat.
  bool get deletable => status != 'ASSIGNED' && status != 'EN_CONTRAT';

  /// Seuls les véhicules vérifiés et opérationnels peuvent être activés.
  bool get usable => isVerified && !{'PENDING', 'REJECTED', 'RETIRED', 'MAINTENANCE', 'SOLD'}.contains(status);

  @override
  List<Object?> get props => [id, kind, make, model, year, color, plate, seats, status, isVerified, isActive, category, activeCategories, selectableCategories, insuranceExpiry];
}

/// Nouveau véhicule : l'assurance (photo) est obligatoire, la carte grise facultative.
class NewVehicle extends Equatable {
  const NewVehicle({
    required this.kind,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.plate,
    required this.seats,
    required this.insurancePath,
    this.registrationPath,
    this.insuranceExpiry,
  });

  final VehicleKind kind;
  final String make;
  final String model;
  final int year;
  final String color;
  final String plate;
  final int seats;
  final String insurancePath;
  final String? registrationPath;
  final DateTime? insuranceExpiry;

  @override
  List<Object?> get props => [kind, make, model, year, color, plate, seats, insurancePath, registrationPath, insuranceExpiry];
}
