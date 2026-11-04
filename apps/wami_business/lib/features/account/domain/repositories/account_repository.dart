import 'package:wami_core/wami_core.dart';

import '../entities/business_account.dart';

abstract interface class AccountRepository {
  Future<Result<BusinessAccount>> getAccount();
  Future<Result<TeamMember>> invite({required String name, required String phone, required TeamRole role});
  Future<Result<void>> removeMember(String memberId);
}
