import 'package:wami_core/wami_core.dart';

import '../entities/driver_profile.dart';
import '../repositories/profile_repository.dart';

class GetProfile implements UseCase<DriverProfile, NoParams> {
  const GetProfile(this._repo);
  final ProfileRepository _repo;

  @override
  Future<Result<DriverProfile>> call(NoParams _) => _repo.getProfile();
}

final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class UpdateProfile implements UseCase<String, ProfileChange> {
  const UpdateProfile(this._repo);
  final ProfileRepository _repo;

  @override
  Future<Result<String>> call(ProfileChange c) async {
    switch (c) {
      case ChangeName(:final firstName, :final lastName):
        if (firstName.trim().isEmpty || lastName.trim().isEmpty) return const Err(ValidationFailure('Indiquez votre prénom et votre nom.'));
      case ChangeAddress(:final city, :final quarter):
        // Bornes du serveur : ville 2-50 caractères, quartier 2-100.
        if (city.trim().length < 2 || city.trim().length > 50) return const Err(ValidationFailure('Ville : 2 à 50 caractères.'));
        if (quarter.trim().length < 2 || quarter.trim().length > 100) return const Err(ValidationFailure('Quartier : 2 à 100 caractères.'));
      case ChangeEmail(:final email):
        if (!_email.hasMatch(email.trim())) return const Err(ValidationFailure('Adresse e-mail invalide.'));
      case ChangePhone(:final phone):
        final digits = phone.replaceAll(RegExp(r'\D'), '');
        if (digits.length != 8 && !(digits.length == 10 && digits.startsWith('01'))) {
          return const Err(ValidationFailure('Numéro invalide : 10 chiffres commençant par 01.'));
        }
      case VerifyEmail(:final code) || VerifyPhone(:final code):
        if (code.trim().isEmpty) return const Err(ValidationFailure('Saisissez le code reçu.'));
    }
    return _repo.change(c);
  }
}

class DeleteAccount implements UseCase<void, String> {
  const DeleteAccount(this._repo);
  final ProfileRepository _repo;

  @override
  Future<Result<void>> call(String password) async {
    if (password.isEmpty) return const Err(ValidationFailure('Saisissez votre mot de passe pour confirmer.'));
    return _repo.deleteAccount(password);
  }
}
