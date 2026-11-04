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
