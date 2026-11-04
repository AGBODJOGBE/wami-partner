import 'package:wami_core/wami_core.dart';

import '../../domain/entities/partner_account.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_data_sources.dart';

class AccountRepositoryImpl implements AccountRepository {
  const AccountRepositoryImpl(this._remote);
  final AccountRemoteDataSource _remote;

  @override
  Future<Result<PartnerAccount>> getAccount() => guard(_remote.account);

  @override
  Future<Result<PartnerPreferences>> savePreferences(PartnerPreferences preferences) =>
      guard(() => _remote.savePreferences(preferences));
}
