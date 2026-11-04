import 'package:wami_core/wami_core.dart';

import '../../../../shared/business_activity.dart';
import '../entities/business.dart';

abstract interface class OnboardingRepository {
  /// `null` : aucun compte sur cet appareil.
  Future<Result<BusinessSession?>> currentSession();
  Future<Result<void>> requestCode(String phone);
  Future<Result<BusinessSession>> verifyCode({required String phone, required String code});
  Future<Result<BusinessSession>> register({
    required Set<BusinessActivity> activities,
    required String businessName,
    required String district,
  });
  Future<Result<VerificationChecklist>> getChecklist();
  Future<Result<VerificationChecklist>> sendItem(String itemId);
  Future<Result<void>> logout();
}
