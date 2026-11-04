import 'package:wami_core/wami_core.dart';

import '../../domain/entities/business_account.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_data_sources.dart';

class AccountRepositoryImpl implements AccountRepository {
  const AccountRepositoryImpl(this._remote);
  final AccountRemoteDataSource _remote;

  @override
  Future<Result<BusinessAccount>> getAccount() => guard(_remote.account);

  @override
  Future<Result<TeamMember>> invite({required String name, required String phone, required TeamRole role}) =>
      guard(() => _remote.invite(name, phone, role));

  @override
  Future<Result<void>> removeMember(String memberId) => guard(() => _remote.remove(memberId));
}
