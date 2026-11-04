import 'package:wami_core/wami_core.dart';

import '../../../../shared/business_activity.dart';
import '../../../../shared/phone.dart';
import '../entities/business.dart';
import '../repositories/onboarding_repository.dart';

class GetSession implements UseCase<BusinessSession?, NoParams> {
  const GetSession(this._repo);
  final OnboardingRepository _repo;

  @override
  Future<Result<BusinessSession?>> call(NoParams _) => _repo.currentSession();
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

class VerifyOtp implements UseCase<BusinessSession, VerifyOtpParams> {
  const VerifyOtp(this._repo);
  final OnboardingRepository _repo;

  @override
  Future<Result<BusinessSession>> call(VerifyOtpParams p) async {
    if (!RegExp(r'^\d{4}$').hasMatch(p.code)) {
      return const Err(ValidationFailure('Le code contient 4 chiffres.'));
    }
    return _repo.verifyCode(phone: normalizePhone(p.phone), code: p.code);
  }
}

class RegisterParams {
  const RegisterParams({required this.activities, required this.businessName, required this.district});
  final Set<BusinessActivity> activities;
  final String businessName;
  final String district;
}

class RegisterBusiness implements UseCase<BusinessSession, RegisterParams> {
  const RegisterBusiness(this._repo);
  final OnboardingRepository _repo;

  @override
  Future<Result<BusinessSession>> call(RegisterParams p) async {
    if (p.activities.isEmpty) return const Err(ValidationFailure('Choisissez au moins une activité.'));
    if (p.businessName.trim().length < 2) return const Err(ValidationFailure('Indiquez le nom de l’établissement.'));
    return _repo.register(activities: p.activities, businessName: p.businessName.trim(), district: p.district.trim());
  }
}

class GetChecklist implements UseCase<VerificationChecklist, NoParams> {
  const GetChecklist(this._repo);
  final OnboardingRepository _repo;

  @override
  Future<Result<VerificationChecklist>> call(NoParams _) => _repo.getChecklist();
}

/// Envoie une pièce. Refusé si elle est déjà en vérification ou validée.
class SendChecklistItem implements UseCase<VerificationChecklist, ChecklistItem> {
  const SendChecklistItem(this._repo);
  final OnboardingRepository _repo;

  @override
  Future<Result<VerificationChecklist>> call(ChecklistItem item) async {
    if (!item.state.needsAction) return const Err(ValidationFailure('Cette pièce est déjà envoyée.'));
    return _repo.sendItem(item.id);
  }
}

class Logout implements UseCase<void, NoParams> {
  const Logout(this._repo);
  final OnboardingRepository _repo;

  @override
  Future<Result<void>> call(NoParams _) => _repo.logout();
}
