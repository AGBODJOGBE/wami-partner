import 'package:wami_core/wami_core.dart';

import '../../domain/entities/partner.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../datasources/onboarding_data_sources.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  const OnboardingRepositoryImpl(this._remote);
  final OnboardingRemoteDataSource _remote;

  @override
  Future<Result<PartnerSession?>> currentSession() => guard(_remote.currentSession);

  @override
  Future<Result<void>> requestCode(String phone) => guard(() => _remote.requestCode(phone));

  @override
  Future<Result<PartnerSession>> verifyCode({required String phone, required String code}) =>
      guard(() => _remote.verifyCode(phone, code));

  @override
  Future<Result<void>> register({required Set<PartnerActivity> activities, required VehicleType vehicle}) =>
      guard(() => _remote.register(activities, vehicle));

  @override
  Future<Result<List<PartnerDocument>>> getDocuments() => guard(_remote.documents);

  @override
  Future<Result<PartnerDocument>> uploadDocument(DocumentType type) => guard(() => _remote.upload(type));

  @override
  Future<Result<void>> submitForReview() => guard(_remote.submit);

  @override
  Future<Result<VerificationProgress>> getVerification() => guard(_remote.verification);

  @override
  Future<Result<void>> completeTraining() => guard(_remote.completeTraining);

  @override
  Future<Result<void>> logout() => guard(_remote.logout);
}
