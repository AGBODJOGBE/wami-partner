import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/business_activity.dart';
import '../../domain/entities/business.dart';
import '../../domain/usecases/onboarding_usecases.dart';

class OnboardingState extends Equatable {
  const OnboardingState({
    this.activities = const {},
    this.businessName = '',
    this.district = '',
    this.phone = '',
    this.checklist,
    this.sendingId,
    this.busy = false,
    this.failure,
  });

  final Set<BusinessActivity> activities;
  final String businessName;
  final String district;
  final String phone;
  final VerificationChecklist? checklist;

  /// Pièce en cours d'envoi.
  final String? sendingId;
  final bool busy;
  final Failure? failure;

  OnboardingState copyWith({
    Set<BusinessActivity>? activities,
    String? businessName,
    String? district,
    String? phone,
    VerificationChecklist? checklist,
    String? sendingId,
    bool clearSending = false,
    bool? busy,
    Failure? failure,
  }) {
    return OnboardingState(
      activities: activities ?? this.activities,
      businessName: businessName ?? this.businessName,
      district: district ?? this.district,
      phone: phone ?? this.phone,
      checklist: checklist ?? this.checklist,
      sendingId: clearSending ? null : (sendingId ?? this.sendingId),
      busy: busy ?? this.busy,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [activities, businessName, district, phone, checklist, sendingId, busy, failure];
}

/// Parcours d'inscription : activités, numéro, code SMS, pièces à fournir.
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit({
    required RequestOtp requestOtp,
    required VerifyOtp verifyOtp,
    required RegisterBusiness register,
    required GetChecklist getChecklist,
    required SendChecklistItem sendItem,
  })  : _requestOtp = requestOtp,
        _verifyOtp = verifyOtp,
        _register = register,
        _getChecklist = getChecklist,
        _sendItem = sendItem,
        super(const OnboardingState());

  final RequestOtp _requestOtp;
  final VerifyOtp _verifyOtp;
  final RegisterBusiness _register;
  final GetChecklist _getChecklist;
  final SendChecklistItem _sendItem;
  Timer? _poll;

  void toggleActivity(BusinessActivity a) {
    final next = {...state.activities};
    next.contains(a) ? next.remove(a) : next.add(a);
    emit(state.copyWith(activities: next));
  }

  void setName(String v) => emit(state.copyWith(businessName: v));
  void setDistrict(String v) => emit(state.copyWith(district: v));
  void setPhone(String v) => emit(state.copyWith(phone: v));

  /// Vérifie le formulaire avant l'envoi du SMS, pour ne pas découvrir une erreur après le code.
  Future<bool> sendCode() async {
    if (state.activities.isEmpty) {
      emit(state.copyWith(failure: const ValidationFailure('Choisissez au moins une activité.')));
      return false;
    }
    if (state.businessName.trim().length < 2) {
      emit(state.copyWith(failure: const ValidationFailure('Indiquez le nom de l’établissement.')));
      return false;
    }
    emit(state.copyWith(busy: true));
    final r = await _requestOtp(state.phone);
    emit(state.copyWith(busy: false, failure: r.fold((f) => f, (_) => null)));
    return r.isOk;
  }

  /// Vérifie le code puis crée l'établissement.
  Future<bool> verify(String code) async {
    emit(state.copyWith(busy: true));
    final v = await _verifyOtp(VerifyOtpParams(phone: state.phone, code: code));
    if (!v.isOk) {
      emit(state.copyWith(busy: false, failure: v.fold((f) => f, (_) => null)));
      return false;
    }
    final r = await _register(RegisterParams(
      activities: state.activities,
      businessName: state.businessName,
      district: state.district,
    ));
    emit(state.copyWith(busy: false, failure: r.fold((f) => f, (_) => null)));
    return r.isOk;
  }

  Future<void> loadChecklist() async {
    final r = await _getChecklist(const NoParams());
    r.fold((f) => emit(state.copyWith(failure: f)), (c) => emit(state.copyWith(checklist: c)));
  }

  Future<void> send(ChecklistItem item) async {
    emit(state.copyWith(sendingId: item.id));
    final r = await _sendItem(item);
    r.fold(
      (f) => emit(state.copyWith(clearSending: true, failure: f)),
      (c) => emit(state.copyWith(clearSending: true, checklist: c)),
    );
  }

  /// Relit la vérification toutes les 3 s jusqu'à validation complète.
  void watchChecklist() {
    _poll?.cancel();
    loadChecklist();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) async {
      await loadChecklist();
      if (state.checklist?.isComplete ?? false) _poll?.cancel();
    });
  }

  @override
  Future<void> close() {
    _poll?.cancel();
    return super.close();
  }
}
