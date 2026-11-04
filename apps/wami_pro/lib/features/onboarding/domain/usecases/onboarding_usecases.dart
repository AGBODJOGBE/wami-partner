import 'package:wami_core/wami_core.dart';

import '../entities/partner.dart';
import '../repositories/onboarding_repository.dart';

/// Normalise un numéro béninois : chiffres seuls.
/// Format accepté : 8 chiffres (ancien) ou 10 chiffres commençant par 01 — à valider.
String normalizePhone(String raw) => raw.replaceAll(RegExp(r'\D'), '');

bool isValidBeninPhone(String digits) =>
    digits.length == 8 || (digits.length == 10 && digits.startsWith('01'));

class GetSession implements UseCase<PartnerSession?, NoParams> {
  const GetSession(this._repo);
  final OnboardingRepository _repo;

  @override
  Future<Result<PartnerSession?>> call(NoParams _) => _repo.currentSession();
}

class RequestOtp implements UseCase<void, String> {
  const RequestOtp(this._repo);
  final OnboardingRepository _repo;

  @override
  Future<Result<void>> call(String phone) async {
    final digits = normalizePhone(phone);
    if (!isValidBeninPhone(digits)) {
      return const Err(ValidationFailure('Numéro invalide : 10 chiffres commençant par 01.'));
    }
    return _repo.requestCode(digits);
  }
}

class VerifyOtpParams {
  const VerifyOtpParams({required this.phone, required this.code});
  final String phone;
  final String code;
}

/// Vérifie le code SMS (6 chiffres). Ne crée pas de session : le compte est créé ensuite.
class VerifyOtp implements UseCase<void, VerifyOtpParams> {
  const VerifyOtp(this._repo);
  final OnboardingRepository _repo;

  @override
  Future<Result<void>> call(VerifyOtpParams p) async {
    if (!RegExp(r'^\d{6}$').hasMatch(p.code)) {
      return const Err(ValidationFailure('Le code contient 6 chiffres.'));
    }
    return _repo.verifyCode(phone: normalizePhone(p.phone), code: p.code);
  }
}

/// Règle du serveur : 8 caractères minimum, une majuscule, une minuscule, un chiffre.
String? passwordProblem(String p) {
  if (p.length < 8 || !RegExp('[A-Z]').hasMatch(p) || !RegExp('[a-z]').hasMatch(p) || !RegExp(r'\d').hasMatch(p)) {
    return 'Mot de passe : 8 caractères minimum, avec une majuscule, une minuscule et un chiffre.';
  }
  return null;
}

class RegisterPartner implements UseCase<PartnerSession, RegistrationForm> {
  const RegisterPartner(this._repo);
  final OnboardingRepository _repo;

  @override
  Future<Result<PartnerSession>> call(RegistrationForm f) async {
    if (f.activities.isEmpty) return const Err(ValidationFailure('Choisissez au moins une activité.'));
    if (f.firstName.trim().isEmpty || f.lastName.trim().isEmpty) {
      return const Err(ValidationFailure('Indiquez votre nom et votre prénom.'));
    }
    final problem = passwordProblem(f.password);
    if (problem != null) return Err(ValidationFailure(problem));
    if (f.make.trim().isEmpty || f.model.trim().isEmpty || f.color.trim().isEmpty || f.plate.trim().isEmpty) {
      return const Err(ValidationFailure('Renseignez la marque, le modèle, la couleur et la plaque du véhicule.'));
    }
    final year = DateTime.now().year;
    if (f.year < 1990 || f.year > year + 1) return const Err(ValidationFailure('Année du véhicule invalide.'));
    return _repo.register(f);
  }
}

class LoginParams {
  const LoginParams({required this.phone, required this.password});
  final String phone;
  final String password;
}

class LoginPartner implements UseCase<PartnerSession, LoginParams> {
  const LoginPartner(this._repo);
  final OnboardingRepository _repo;

  @override
  Future<Result<PartnerSession>> call(LoginParams p) async {
    final digits = normalizePhone(p.phone);
    if (!isValidBeninPhone(digits)) {
      return const Err(ValidationFailure('Numéro invalide : 10 chiffres commençant par 01.'));
    }
    if (p.password.isEmpty) return const Err(ValidationFailure('Saisissez votre mot de passe.'));
    return _repo.login(phone: digits, password: p.password);
  }
}

class RequestPasswordReset implements UseCase<void, String> {
  const RequestPasswordReset(this._repo);
  final OnboardingRepository _repo;

  @override
  Future<Result<void>> call(String phone) async {
    final digits = normalizePhone(phone);
    if (!isValidBeninPhone(digits)) {
      return const Err(ValidationFailure('Numéro invalide : 10 chiffres commençant par 01.'));
    }
    return _repo.requestPasswordReset(digits);
  }
}

class ResetPasswordParams {
  const ResetPasswordParams({required this.phone, required this.code, required this.newPassword});
  final String phone;
  final String code;
  final String newPassword;
}

class ResetPassword implements UseCase<void, ResetPasswordParams> {
  const ResetPassword(this._repo);
  final OnboardingRepository _repo;

  @override
  Future<Result<void>> call(ResetPasswordParams p) async {
    if (p.code.trim().isEmpty) return const Err(ValidationFailure('Saisissez le code reçu par SMS.'));
    final problem = passwordProblem(p.newPassword);
    if (problem != null) return Err(ValidationFailure(problem));
    return _repo.resetPassword(phone: normalizePhone(p.phone), code: p.code.trim(), newPassword: p.newPassword);
  }
}

class GetDocuments implements UseCase<List<PartnerDocument>, NoParams> {
  const GetDocuments(this._repo);
  final OnboardingRepository _repo;

  @override
  Future<Result<List<PartnerDocument>>> call(NoParams _) => _repo.getDocuments();
}

class UploadParams {
  const UploadParams({required this.type, required this.filePath});
  final DocumentType type;
  final String filePath;
}

class UploadDocument implements UseCase<PartnerDocument, UploadParams> {
  const UploadDocument(this._repo);
  final OnboardingRepository _repo;

  @override
  Future<Result<PartnerDocument>> call(UploadParams p) => _repo.uploadDocument(p.type, p.filePath);
}

/// Règle : on ne soumet le dossier que si aucune pièce n'est manquante ou refusée.
class SubmitForReview implements UseCase<void, List<PartnerDocument>> {
  const SubmitForReview(this._repo);
  final OnboardingRepository _repo;

  @override
  Future<Result<void>> call(List<PartnerDocument> docs) async {
    final blocking = docs.where((d) => !d.status.isSent).toList();
    if (blocking.isNotEmpty) {
      return Err(ValidationFailure('Il reste ${blocking.length} pièce(s) à envoyer.'));
    }
    return _repo.submitForReview();
  }
}

class GetVerification implements UseCase<VerificationProgress, NoParams> {
  const GetVerification(this._repo);
  final OnboardingRepository _repo;

  @override
  Future<Result<VerificationProgress>> call(NoParams _) => _repo.getVerification();
}

class CompleteTraining implements UseCase<void, NoParams> {
  const CompleteTraining(this._repo);
  final OnboardingRepository _repo;

  @override
  Future<Result<void>> call(NoParams _) => _repo.completeTraining();
}

class Logout implements UseCase<void, NoParams> {
  const Logout(this._repo);
  final OnboardingRepository _repo;

  @override
  Future<Result<void>> call(NoParams _) => _repo.logout();
}
