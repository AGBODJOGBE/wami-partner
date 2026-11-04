import 'package:equatable/equatable.dart';

class DriverProfile extends Equatable {
  const DriverProfile({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.phoneVerified,
    required this.email,
    required this.emailVerified,
    required this.city,
    required this.quarter,
  });

  final String firstName;
  final String lastName;
  final String phone;
  final bool phoneVerified;
  final String? email;
  final bool emailVerified;
  final String city;
  final String quarter;

  @override
  List<Object?> get props => [firstName, lastName, phone, phoneVerified, email, emailVerified, city, quarter];
}

/// Action sur le profil, exécutée par un seul cas d'usage.
sealed class ProfileChange {
  const ProfileChange();
}

final class ChangeName extends ProfileChange {
  const ChangeName(this.firstName, this.lastName);
  final String firstName;
  final String lastName;
}

final class ChangeAddress extends ProfileChange {
  const ChangeAddress(this.city, this.quarter);
  final String city;
  final String quarter;
}

/// Ajoute l'e-mail s'il n'y en a pas encore, le remplace sinon. Un code est envoyé pour le confirmer.
final class ChangeEmail extends ProfileChange {
  const ChangeEmail(this.email, {required this.hadEmail});
  final String email;
  final bool hadEmail;
}

final class VerifyEmail extends ProfileChange {
  const VerifyEmail(this.code);
  final String code;
}

final class ChangePhone extends ProfileChange {
  const ChangePhone(this.phone);
  final String phone;
}

final class VerifyPhone extends ProfileChange {
  const VerifyPhone(this.code);
  final String code;
}
