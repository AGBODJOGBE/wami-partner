import 'package:wami_core/wami_core.dart';

import '../entities/partner_account.dart';
import '../repositories/account_repository.dart';

class GetPartnerAccount implements UseCase<PartnerAccount, NoParams> {
  const GetPartnerAccount(this._repo);
  final AccountRepository _repo;

  @override
  Future<Result<PartnerAccount>> call(NoParams _) => _repo.getAccount();
}

class SavePreferences implements UseCase<PartnerPreferences, PartnerPreferences> {
  const SavePreferences(this._repo);
  final AccountRepository _repo;

  @override
  Future<Result<PartnerPreferences>> call(PartnerPreferences p) => _repo.savePreferences(p);
}

class ChangePasswordParams {
  const ChangePasswordParams({required this.current, required this.next, required this.confirm});
  final String current;
  final String next;
  final String confirm;
}

class ChangePassword implements UseCase<void, ChangePasswordParams> {
  const ChangePassword(this._repo);
  final AccountRepository _repo;

  @override
  Future<Result<void>> call(ChangePasswordParams p) async {
    if (p.current.isEmpty) return const Err(ValidationFailure('Saisissez votre mot de passe actuel.'));
    // Règle du serveur : 8 caractères minimum, une majuscule, une minuscule, un chiffre.
    if (p.next.length < 8 ||
        !RegExp('[A-Z]').hasMatch(p.next) ||
        !RegExp('[a-z]').hasMatch(p.next) ||
        !RegExp(r'\d').hasMatch(p.next)) {
      return const Err(ValidationFailure('Mot de passe : 8 caractères minimum, avec une majuscule, une minuscule et un chiffre.'));
    }
    if (p.next != p.confirm) return const Err(ValidationFailure('Les deux mots de passe ne correspondent pas.'));
    return _repo.changePassword(current: p.current, next: p.next);
  }
}
