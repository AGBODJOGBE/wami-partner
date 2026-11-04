import 'package:equatable/equatable.dart';
import 'package:wami_core/wami_core.dart';

enum PartnerActivity {
  driver('Chauffeur', 'Transport de personnes'),
  courier('Livreur', 'Colis et repas');

  const PartnerActivity(this.label, this.hint);
  final String label;
  final String hint;
}

enum VehicleType {
  moto('Moto', ServiceArt.moto),
  tricycle('Tricycle', ServiceArt.moto),
  car('Voiture', ServiceArt.auto),
  van('Van', ServiceArt.auto);

  const VehicleType(this.label, this.art);
  final String label;
  final ServiceArt art;
}

enum DocumentType {
  identity('Pièce d’identité', null),
  photo('Photo de profil', null),
  license('Permis de conduire', null),
  registration('Carte grise', null),
  insurance('Assurance', null),
  vehiclePhotos('Photos du véhicule', 'Avant, arrière, plaque');

  const DocumentType(this.label, this.hint);
  final String label;
  final String? hint;

  /// Pièces exigées. Liste à valider (casier judiciaire ? visite technique ?).
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
