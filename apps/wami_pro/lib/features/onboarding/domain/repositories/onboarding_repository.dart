import 'package:wami_core/wami_core.dart';

import '../entities/partner.dart';

abstract interface class OnboardingRepository {
  /// Session enregistrée sur le téléphone, avec l'avancement du dossier.
  Future<Result<PartnerSession?>> currentSession();

  /// Envoie le code SMS. Étapes imposées par le serveur : code → vérification → création → connexion.
  Future<Result<void>> requestCode(String phone);
  Future<Result<void>> verifyCode({required String phone, required String code});

  /// Crée le compte (le numéro doit avoir été vérifié) puis ouvre la session.
  Future<Result<PartnerSession>> register(RegistrationForm form);
  Future<Result<PartnerSession>> login({required String phone, required String password});
  Future<Result<void>> requestPasswordReset(String phone);
  Future<Result<void>> resetPassword({required String phone, required String code, required String newPassword});

  Future<Result<List<PartnerDocument>>> getDocuments();

  /// Envoi d'une photo de pièce (chemin du fichier pris avec la caméra).
  Future<Result<PartnerDocument>> uploadDocument(DocumentType type, String filePath);
  Future<Result<void>> submitForReview();
  Future<Result<VerificationProgress>> getVerification();
  Future<Result<void>> completeTraining();
  Future<Result<void>> logout();
}
