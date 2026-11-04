import 'package:equatable/equatable.dart';
import 'package:wami_core/wami_core.dart';

enum PartnerActivity {
  driver('Chauffeur', 'Transport de personnes'),
  courier('Livreur', 'Colis et repas');

  const PartnerActivity(this.label, this.hint);
  final String label;
  final String hint;

  /// Valeur `driverType` du serveur : `VTC`, `DELIVERY` ou `BOTH`.
  static String apiType(Set<PartnerActivity> a) => switch ((a.contains(driver), a.contains(courier))) {
        (true, true) => 'BOTH',
        (false, true) => 'DELIVERY',
        _ => 'VTC',
      };
}

enum VehicleType {
  moto('Moto', ServiceArt.moto),
  tricycle('Tricycle', ServiceArt.moto),
  car('Voiture', ServiceArt.auto);

  const VehicleType(this.label, this.art);
  final String label;
  final ServiceArt art;

  /// Valeur du serveur : `MOTO`, `TRICYCLE` ou `CAR`.
  String get apiName => name.toUpperCase();

  int get defaultSeats => this == car ? 4 : (this == tricycle ? 3 : 1);
}

enum Gender {
  male('Homme', 'MALE'),
  female('Femme', 'FEMALE');

  const Gender(this.label, this.apiName);
  final String label;
  final String apiName;
}

/// Informations saisies à la création du compte (le serveur impose le véhicule
/// quand le chauffeur en est propriétaire).
class RegistrationForm extends Equatable {
  const RegistrationForm({
    required this.phone,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.activities,
    required this.vehicle,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.plate,
    required this.seats,
  });

  final String phone;
  final String password;
  final String firstName;
  final String lastName;
  final Gender gender;
  final Set<PartnerActivity> activities;
  final VehicleType vehicle;
  final String make;
  final String model;
  final int year;
  final String color;
  final String plate;
  final int seats;

  @override
  List<Object?> get props =>
      [phone, firstName, lastName, gender, activities, vehicle, make, model, year, color, plate, seats];
}

enum DocumentType {
  identity('Pièce d’identité', null),
  photo('Photo de profil', null),
  license('Permis de conduire', null),
  registration('Carte grise', null),
  insurance('Assurance', null);

  const DocumentType(this.label, this.hint);
  final String label;
  final String? hint;

  /// Type du serveur (`DocumentType` côté API).
  String get apiName => switch (this) {
        identity => 'IDENTITY_CARD',
        photo => 'PROFILE_PHOTO',
        license => 'DRIVERS_LICENSE',
        registration => 'REGISTRATION_CARD',
        insurance => 'INSURANCE',
      };

  /// Les pièces du véhicule se rattachent au véhicule, les autres au chauffeur.
  bool get belongsToVehicle => this == registration || this == insurance;

  /// Pièces exigées. Le casier judiciaire existe côté serveur mais n'est pas demandé ici.
  static List<DocumentType> requiredFor(Set<PartnerActivity> activities, VehicleType vehicle) {
    return DocumentType.values;
  }
}

enum DocumentStatus {
  missing('À envoyer'),
  pending('En vérification'),
  approved('Validé'),
  rejected('Refusé');

  const DocumentStatus(this.label);
  final String label;

  bool get isSent => this == pending || this == approved;
}

class PartnerDocument extends Equatable {
  const PartnerDocument({required this.type, required this.status, this.rejectionReason});
  final DocumentType type;
  final DocumentStatus status;
  final String? rejectionReason;

  @override
  List<Object?> get props => [type, status, rejectionReason];
}

enum PartnerStatus { newcomer, underReview, active, suspended }

class PartnerSession extends Equatable {
  const PartnerSession({required this.phone, required this.status});
  final String phone;
  final PartnerStatus status;

  @override
  List<Object?> get props => [phone, status];
}

/// Avancement du dossier après l'envoi des documents.
class VerificationProgress extends Equatable {
  const VerificationProgress({
    required this.documentsSent,
    required this.reviewDone,
    required this.trainingDone,
    required this.vehicleChecked,
    this.reviewDelay = '[48 h]',
  });

  final bool documentsSent;
  final bool reviewDone;
  final bool trainingDone;
  final bool vehicleChecked;

  /// Délai annoncé de vérification (à valider).
  final String reviewDelay;

  bool get isActive => documentsSent && reviewDone && trainingDone && vehicleChecked;

  @override
  List<Object?> get props => [documentsSent, reviewDone, trainingDone, vehicleChecked, reviewDelay];
}
