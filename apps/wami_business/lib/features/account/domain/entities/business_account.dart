import 'package:equatable/equatable.dart';

enum TeamRole {
  owner('Propriétaire', 'Tout, y compris finances et équipe'),
  manager('Gérant', 'Activité, offre et avis. Pas les finances'),
  staff('Employé', 'Activité du jour uniquement');

  const TeamRole(this.label, this.rights);
  final String label;
  final String rights;
}

class TeamMember extends Equatable {
  const TeamMember({required this.id, required this.name, required this.phone, required this.role, this.pending = false});
  final String id;
  final String name;
  final String phone;
  final TeamRole role;

  /// Invitation envoyée, pas encore acceptée.
  final bool pending;

  @override
  List<Object?> get props => [id, name, phone, role, pending];
}

class BusinessAccount extends Equatable {
  const BusinessAccount({
    required this.businessName,
    required this.ownerName,
    required this.phone,
    required this.memberSince,
    required this.team,
  });

  final String businessName;
  final String ownerName;
  final String phone;
  final String memberSince;
  final List<TeamMember> team;

  BusinessAccount copyWith({List<TeamMember>? team}) => BusinessAccount(
        businessName: businessName,
        ownerName: ownerName,
        phone: phone,
        memberSince: memberSince,
        team: team ?? this.team,
      );

  @override
  List<Object?> get props => [businessName, ownerName, phone, memberSince, team];
}
