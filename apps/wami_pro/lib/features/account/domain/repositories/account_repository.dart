import 'package:wami_core/wami_core.dart';

import '../entities/partner_account.dart';

abstract interface class AccountRepository {
  Future<Result<PartnerAccount>> getAccount();
  Future<Result<PartnerPreferences>> savePreferences(PartnerPreferences preferences);
  Future<Result<void>> changePassword({required String current, required String next});
}
