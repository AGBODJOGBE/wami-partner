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

class VerifyOtp implements UseCase<PartnerSession, VerifyOtpParams> {
  const VerifyOtp(this._repo);
  final OnboardingRepository _repo;

  @override
  Future<Result<PartnerSession>> call(VerifyOtpParams p) async {
    if (!RegExp(r'^\d{4}$').hasMatch(p.code)) {
      return const Err(ValidationFailure('Le code contient 4 chiffres.'));
    }
    return _repo.verifyCode(phone: normalizePhone(p.phone), code: p.code);
  }
}

class RegisterParams {
  const RegisterParams({required this.activities, required this.vehicle});
  final Set<PartnerActivity> activities;
  final VehicleType vehicle;
}

class RegisterPartner implements UseCase<void, RegisterParams> {
  const RegisterPartner(this._repo);
  final OnboardingRepository _repo;

  @override
  Future<Result<void>> call(RegisterParams p) async {
    if (p.activities.isEmpty) return const Err(ValidationFailure('Choisissez au moins une activité.'));
    return _repo.register(activities: p.activities, vehicle: p.vehicle);
  }
}

class GetDocuments implements UseCase<List<PartnerDocument>, NoParams> {
  const GetDocuments(this._repo);
  final OnboardingRepository _repo;

  @override
  Future<Result<List<PartnerDocument>>> call(NoParams _) => _repo.getDocuments();
}

class UploadDocument implements UseCase<PartnerDocument, DocumentType> {
  const UploadDocument(this._repo);
  final OnboardingRepository _repo;

  @override
  Future<Result<PartnerDocument>> call(DocumentType type) => _repo.uploadDocument(type);
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
