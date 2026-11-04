import 'package:wami_core/wami_core.dart';

import '../../../../shared/business_activity.dart';
import '../../domain/entities/business.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../datasources/onboarding_data_sources.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  const OnboardingRepositoryImpl(this._remote);
  final OnboardingRemoteDataSource _remote;

  @override
  Future<Result<BusinessSession?>> currentSession() => guard(_remote.currentSession);

  @override
  Future<Result<void>> requestCode(String phone) => guard(() => _remote.requestCode(phone));

  @override
  Future<Result<BusinessSession>> verifyCode({required String phone, required String code}) =>
      guard(() => _remote.verifyCode(phone, code));

  @override
  Future<Result<BusinessSession>> register({
    required Set<BusinessActivity> activities,
    required String businessName,
    required String district,
  }) =>
      guard(() => _remote.register(activities, businessName, district));

  @override
  Future<Result<VerificationChecklist>> getChecklist() => guard(_remote.checklist);

  @override
  Future<Result<VerificationChecklist>> sendItem(String itemId) => guard(() => _remote.sendItem(itemId));

  @override
  Future<Result<void>> logout() => guard(_remote.logout);
}
