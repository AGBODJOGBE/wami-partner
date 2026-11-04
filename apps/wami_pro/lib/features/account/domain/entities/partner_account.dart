import 'package:equatable/equatable.dart';

enum ComplianceState { ok, expiringSoon, expired }

/// Pièce à tenir à jour (permis, assurance…).
class ComplianceItem extends Equatable {
  const ComplianceItem({required this.label, required this.state, this.daysLeft});
  final String label;
  final ComplianceState state;
  final int? daysLeft;

  @override
  List<Object?> get props => [label, state, daysLeft];
}

class PartnerPreferences extends Equatable {
  const PartnerPreferences({this.acceptDeliveries = true, this.acceptCash = true, this.longTrips = false});
  final bool acceptDeliveries;
  final bool acceptCash;

  /// Courses hors de la ville.
  final bool longTrips;

  PartnerPreferences copyWith({bool? acceptDeliveries, bool? acceptCash, bool? longTrips}) => PartnerPreferences(
        acceptDeliveries: acceptDeliveries ?? this.acceptDeliveries,
        acceptCash: acceptCash ?? this.acceptCash,
        longTrips: longTrips ?? this.longTrips,
      );

  @override
  List<Object?> get props => [acceptDeliveries, acceptCash, longTrips];
}

class PartnerAccount extends Equatable {
  const PartnerAccount({
    required this.name,
    required this.role,
    required this.memberSince,
    required this.vehicle,
    required this.plate,
    required this.compliance,
    required this.preferences,
  });

  final String name;
  final String role;
  final String memberSince;
  final String vehicle;
  final String plate;
  final List<ComplianceItem> compliance;
  final PartnerPreferences preferences;

  /// Une pièce expirée bloque le passage en ligne.
  bool get blocked => compliance.any((c) => c.state == ComplianceState.expired);

  PartnerAccount copyWith({PartnerPreferences? preferences}) => PartnerAccount(
        name: name,
        role: role,
        memberSince: memberSince,
        vehicle: vehicle,
        plate: plate,
        compliance: compliance,
        preferences: preferences ?? this.preferences,
      );

  @override
  List<Object?> get props => [name, role, memberSince, vehicle, plate, compliance, preferences];
}
