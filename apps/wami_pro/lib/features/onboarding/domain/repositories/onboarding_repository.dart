import 'package:wami_core/wami_core.dart';

import '../entities/partner.dart';

abstract interface class OnboardingRepository {
  Future<Result<PartnerSession?>> currentSession();
  Future<Result<void>> requestCode(String phone);
  Future<Result<PartnerSession>> verifyCode({required String phone, required String code});
  Future<Result<void>> register({required Set<PartnerActivity> activities, required VehicleType vehicle});
  Future<Result<List<PartnerDocument>>> getDocuments();

  /// Envoi d'une photo de document. Le fichier image sera ajouté au branchement
  /// de la caméra (image_picker / camera) — à brancher.
  Future<Result<PartnerDocument>> uploadDocument(DocumentType type);
  Future<Result<void>> submitForReview();
  Future<Result<VerificationProgress>> getVerification();
  Future<Result<void>> completeTraining();
  Future<Result<void>> logout();
}
