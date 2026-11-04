import 'package:wami_core/wami_core.dart';

import '../../domain/entities/referral.dart';
import '../../domain/repositories/referrals_repository.dart';
import '../datasources/referrals_data_sources.dart';

class ReferralsRepositoryImpl implements ReferralsRepository {
  const ReferralsRepositoryImpl(this._remote);
  final ReferralsRemoteDataSource _remote;

  @override
  Future<Result<ReferralOverview>> getOverview() => guard(_remote.overview);

  @override
  Future<Result<String>> apply(String code) => guard(() => _remote.apply(code));

  @override
  Future<Result<String>> validate() => guard(_remote.validate);
}
