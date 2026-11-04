import 'package:wami_core/wami_core.dart';

import '../entities/referral.dart';
import '../repositories/referrals_repository.dart';

class GetReferrals implements UseCase<ReferralOverview, NoParams> {
  const GetReferrals(this._repo);
  final ReferralsRepository _repo;

  @override
  Future<Result<ReferralOverview>> call(NoParams _) => _repo.getOverview();
}

class ApplyReferralCode implements UseCase<String, String> {
  const ApplyReferralCode(this._repo);
  final ReferralsRepository _repo;

  @override
  Future<Result<String>> call(String code) async {
    if (code.trim().isEmpty) return const Err(ValidationFailure('Saisissez un code de parrainage.'));
    return _repo.apply(code.trim().toUpperCase());
  }
}

class ValidateMyReferral implements UseCase<String, NoParams> {
  const ValidateMyReferral(this._repo);
  final ReferralsRepository _repo;

  @override
  Future<Result<String>> call(NoParams _) => _repo.validate();
}
