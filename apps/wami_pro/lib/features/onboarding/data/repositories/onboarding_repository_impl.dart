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
  Future<Result<void>> verifyCode({required String phone, required String code}) =>
      guard(() => _remote.verifyCode(phone, code));

  @override
  Future<Result<PartnerSession>> register(RegistrationForm form) => guard(() => _remote.register(form));

  @override
  Future<Result<PartnerSession>> login({required String phone, required String password}) =>
      guard(() => _remote.login(phone, password));

  @override
  Future<Result<void>> requestPasswordReset(String phone) => guard(() => _remote.forgotPassword(phone));

  @override
  Future<Result<void>> resetPassword({required String phone, required String code, required String newPassword}) =>
      guard(() => _remote.resetPassword(phone, code, newPassword));

  @override
  Future<Result<List<PartnerDocument>>> getDocuments() => guard(_remote.documents);

  @override
  Future<Result<PartnerDocument>> uploadDocument(DocumentType type, String filePath) =>
      guard(() => _remote.upload(type, filePath));

  @override
  Future<Result<void>> submitForReview() => guard(_remote.submit);

  @override
  Future<Result<VerificationProgress>> getVerification() => guard(_remote.verification);

  @override
  Future<Result<void>> completeTraining() => guard(_remote.completeTraining);

  @override
  Future<Result<void>> logout() => guard(_remote.logout);
}
