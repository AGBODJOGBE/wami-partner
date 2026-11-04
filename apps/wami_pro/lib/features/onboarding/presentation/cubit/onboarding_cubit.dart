import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../domain/entities/partner.dart';
import '../../domain/usecases/onboarding_usecases.dart';

class OnboardingState extends Equatable {
  const OnboardingState({
    this.activities = const {PartnerActivity.driver},
    this.vehicle = VehicleType.moto,
    this.phone = '',
    this.busy = false,
    this.codeSent = false,
    this.session,
    this.documents = const [],
    this.uploading,
    this.verification,
    this.failure,
  });

  final Set<PartnerActivity> activities;
  final VehicleType vehicle;
  final String phone;
  final bool busy;
  final bool codeSent;
  final PartnerSession? session;
  final List<PartnerDocument> documents;
  final DocumentType? uploading;
  final VerificationProgress? verification;
  final Failure? failure;

  int get sentCount => documents.where((d) => d.status.isSent).length;
  bool get allSent => documents.isNotEmpty && sentCount == documents.length;

  OnboardingState copyWith({
    Set<PartnerActivity>? activities,
    VehicleType? vehicle,
    String? phone,
    bool? busy,
    bool? codeSent,
    PartnerSession? session,
    List<PartnerDocument>? documents,
    DocumentType? uploading,
    bool clearUploading = false,
    VerificationProgress? verification,
    Failure? failure,
  }) {
    return OnboardingState(
      activities: activities ?? this.activities,
      vehicle: vehicle ?? this.vehicle,
      phone: phone ?? this.phone,
      busy: busy ?? this.busy,
      codeSent: codeSent ?? this.codeSent,
      session: session ?? this.session,
      documents: documents ?? this.documents,
      uploading: clearUploading ? null : (uploading ?? this.uploading),
      verification: verification ?? this.verification,
      failure: failure,
    );
  }

  @override
  List<Object?> get props =>
      [activities, vehicle, phone, busy, codeSent, session, documents, uploading, verification, failure];
}

/// Parcours d'inscription : métier → numéro → code → documents → vérification.
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit({
    required RequestOtp requestOtp,
    required VerifyOtp verifyOtp,
    required RegisterPartner register,
    required GetDocuments getDocuments,
    required UploadDocument upload,
    required SubmitForReview submit,
    required GetVerification getVerification,
    required CompleteTraining completeTraining,
  })  : _requestOtp = requestOtp,
        _verifyOtp = verifyOtp,
        _register = register,
        _getDocuments = getDocuments,
        _upload = upload,
        _submit = submit,
        _getVerification = getVerification,
        _completeTraining = completeTraining,
        super(const OnboardingState());

  final RequestOtp _requestOtp;
  final VerifyOtp _verifyOtp;
  final RegisterPartner _register;
  final GetDocuments _getDocuments;
  final UploadDocument _upload;
  final SubmitForReview _submit;
  final GetVerification _getVerification;
  final CompleteTraining _completeTraining;
  Timer? _poll;

  void toggleActivity(PartnerActivity a) {
    final set = {...state.activities};
    if (!set.remove(a)) set.add(a);
    emit(state.copyWith(activities: set));
  }

  void setVehicle(VehicleType v) => emit(state.copyWith(vehicle: v));
  void setPhone(String p) => emit(state.copyWith(phone: p));

  Future<bool> sendCode() async {
    emit(state.copyWith(busy: true));
    final r = await _requestOtp(state.phone);
    emit(state.copyWith(busy: false, codeSent: r.isOk, failure: r.fold((f) => f, (_) => null)));
    return r.isOk;
  }

  Future<bool> verify(String code) async {
    emit(state.copyWith(busy: true));
    final r = await _verifyOtp(VerifyOtpParams(phone: state.phone, code: code));
    final session = r.valueOrNull;
    if (session == null) {
      emit(state.copyWith(busy: false, failure: r.fold((f) => f, (_) => null)));
      return false;
    }
    final reg = await _register(RegisterParams(activities: state.activities, vehicle: state.vehicle));
    emit(state.copyWith(busy: false, session: session, failure: reg.fold((f) => f, (_) => null)));
    return reg.isOk;
  }

  Future<void> loadDocuments() async {
    final r = await _getDocuments(const NoParams());
    emit(r.fold((f) => state.copyWith(failure: f), (docs) => state.copyWith(documents: docs)));
  }

  Future<void> upload(DocumentType type) async {
    emit(state.copyWith(uploading: type));
    final r = await _upload(type);
    r.fold(
      (f) => emit(state.copyWith(clearUploading: true, failure: f)),
      (doc) => emit(state.copyWith(
        clearUploading: true,
        documents: [for (final d in state.documents) d.type == doc.type ? doc : d],
      )),
    );
  }

  Future<bool> submit() async {
    emit(state.copyWith(busy: true));
    final r = await _submit(state.documents);
    emit(state.copyWith(busy: false, failure: r.fold((f) => f, (_) => null)));
    return r.isOk;
  }

  /// Interroge l'avancement toutes les 3 s tant que le compte n'est pas actif.
  void watchVerification() {
    _poll?.cancel();
    Future<void> tick() async {
      final r = await _getVerification(const NoParams());
      final v = r.valueOrNull;
      if (isClosed) return;
      if (v != null) emit(state.copyWith(verification: v));
      if (v?.isActive ?? false) _poll?.cancel();
    }

    tick();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => tick());
  }

  Future<void> doTraining() async {
    emit(state.copyWith(busy: true));
    await _completeTraining(const NoParams());
    final r = await _getVerification(const NoParams());
    emit(state.copyWith(busy: false, verification: r.valueOrNull));
  }

  @override
  Future<void> close() {
    _poll?.cancel();
    return super.close();
  }
}
