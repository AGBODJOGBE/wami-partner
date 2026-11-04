import 'package:wami_core/wami_core.dart';

import '../../../../shared/phone.dart';
import '../entities/business_account.dart';
import '../repositories/account_repository.dart';

class GetBusinessAccount implements UseCase<BusinessAccount, NoParams> {
  const GetBusinessAccount(this._repo);
  final AccountRepository _repo;

  @override
  Future<Result<BusinessAccount>> call(NoParams _) => _repo.getAccount();
}

class InviteParams {
  const InviteParams({required this.team, required this.name, required this.phone, required this.role});
  final List<TeamMember> team;
  final String name;
  final String phone;
  final TeamRole role;
}

/// Invite un membre par SMS. Un seul propriétaire ; pas de doublon de numéro.
class InviteMember implements UseCase<TeamMember, InviteParams> {
  const InviteMember(this._repo);
  final AccountRepository _repo;

  @override
  Future<Result<TeamMember>> call(InviteParams p) async {
    if (p.role == TeamRole.owner) return const Err(ValidationFailure('Il ne peut y avoir qu’un propriétaire.'));
    if (p.name.trim().length < 2) return const Err(ValidationFailure('Indiquez le nom du membre.'));
    final digits = normalizePhone(p.phone);
    if (!isValidBeninPhone(digits)) return const Err(ValidationFailure('Numéro invalide : 10 chiffres commençant par 01.'));
    if (p.team.any((m) => normalizePhone(m.phone) == digits)) {
      return const Err(ValidationFailure('Ce numéro fait déjà partie de l’équipe.'));
    }
    return _repo.invite(name: p.name.trim(), phone: digits, role: p.role);
  }
}

class RemoveMember implements UseCase<void, TeamMember> {
  const RemoveMember(this._repo);
  final AccountRepository _repo;

  @override
  Future<Result<void>> call(TeamMember m) async {
    if (m.role == TeamRole.owner) return const Err(ValidationFailure('Le propriétaire ne peut pas être retiré.'));
    return _repo.removeMember(m.id);
  }
}
