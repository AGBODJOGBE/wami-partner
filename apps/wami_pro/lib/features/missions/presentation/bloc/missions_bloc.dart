import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../domain/entities/fare.dart';
import '../../domain/entities/mission.dart';
import '../../domain/usecases/missions_usecases.dart';

// ─── Événements ──────────────────────────────────────────────────────────────

sealed class MissionsEvent extends Equatable {
  const MissionsEvent();
  @override
  List<Object?> get props => [];
}

final class MissionsStarted extends MissionsEvent {
  const MissionsStarted();
}

final class OnlineToggled extends MissionsEvent {
  const OnlineToggled();
}

final class _OfferArrived extends MissionsEvent {
  const _OfferArrived(this.offer);
  final MissionOffer offer;
  @override
  List<Object?> get props => [offer];
}

final class _Ticked extends MissionsEvent {
  const _Ticked(this.now);
  final DateTime now;
  @override
  List<Object?> get props => [now];
}

final class OfferAccepted extends MissionsEvent {
  const OfferAccepted();
}

final class OfferDeclined extends MissionsEvent {
  const OfferDeclined();
}

final class ArrivedPressed extends MissionsEvent {
  const ArrivedPressed();
}

final class StartRequested extends MissionsEvent {
  const StartRequested(this.code);
  final String code;
  @override
  List<Object?> get props => [code];
}

final class PauseToggled extends MissionsEvent {
  const PauseToggled();
}

final class CompleteRequested extends MissionsEvent {
  const CompleteRequested();
}

final class PickupConfirmed extends MissionsEvent {
  const PickupConfirmed({required this.checked, required this.photoTaken});
  final Set<String> checked;
  final bool photoTaken;
  @override
  List<Object?> get props => [checked, photoTaken];
}

final class HandoverConfirmed extends MissionsEvent {
  const HandoverConfirmed({required this.code, required this.collectedWith});
  final String code;
  final PaymentMode collectedWith;
  @override
  List<Object?> get props => [code, collectedWith];
}

final class ReceiptClosed extends MissionsEvent {
  const ReceiptClosed({required this.stars});
  final int stars;
  @override
  List<Object?> get props => [stars];
}

// ─── État ────────────────────────────────────────────────────────────────────

class MissionsState extends Equatable {
  MissionsState({
    this.status = LoadStatus.idle,
    this.day,
    this.policy = const FarePolicy(),
    this.offer,
    this.offerRemaining = 0,
    this.active,
    DateTime? now,
    this.receipt,
    this.busy = false,
    this.failure,
  }) : now = now ?? DateTime.now();

  final LoadStatus status;
  final DriverDay? day;
  final FarePolicy policy;
  final MissionOffer? offer;
  final int offerRemaining;
  final ActiveMission? active;

  /// Horloge partagée par les compteurs (attente, pause, avancement).
  final DateTime now;

  /// Récapitulatif de la dernière mission terminée.
  final MissionReceipt? receipt;
  final bool busy;
  final Failure? failure;

  bool get online => day?.online ?? false;

  /// Montant en cours (course) : prix + attente + pause.
  MissionReceipt? get liveFare => active == null ? null : MissionReceipt.compute(active!, policy, now);

  MissionsState copyWith({
    LoadStatus? status,
    DriverDay? day,
    FarePolicy? policy,
    MissionOffer? offer,
    bool clearOffer = false,
    int? offerRemaining,
    ActiveMission? active,
    bool clearActive = false,
    DateTime? now,
    MissionReceipt? receipt,
    bool clearReceipt = false,
    bool? busy,
    Failure? failure,
  }) {
    return MissionsState(
      status: status ?? this.status,
      day: day ?? this.day,
      policy: policy ?? this.policy,
      offer: clearOffer ? null : (offer ?? this.offer),
      offerRemaining: offerRemaining ?? this.offerRemaining,
      active: clearActive ? null : (active ?? this.active),
      now: now ?? this.now,
      receipt: clearReceipt ? null : (receipt ?? this.receipt),
      busy: busy ?? this.busy,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [status, day, policy, offer, offerRemaining, active, now, receipt, busy, failure];
}

// ─── Bloc ────────────────────────────────────────────────────────────────────

/// Cœur de WAMI Pro : disponibilité, propositions, mission en cours.
class MissionsBloc extends Bloc<MissionsEvent, MissionsState> {
  MissionsBloc({
    required GetDriverDay getDay,
    required GetFarePolicy getPolicy,
    required SetOnline setOnline,
    required WatchOffers watchOffers,
    required AcceptMission accept,
    required DeclineMission decline,
    required MarkArrived arrived,
    required StartTrip start,
    required TogglePause togglePause,
    required CompleteTrip complete,
    required ConfirmPickup confirmPickup,
    required ConfirmHandover handover,
    required RateCustomer rate,
  })  : _getDay = getDay,
        _getPolicy = getPolicy,
        _setOnline = setOnline,
        _watchOffers = watchOffers,
        _accept = accept,
        _decline = decline,
        _arrived = arrived,
        _start = start,
        _togglePause = togglePause,
        _complete = complete,
        _confirmPickup = confirmPickup,
        _handover = handover,
        _rate = rate,
        super(MissionsState()) {
    on<MissionsStarted>(_onStarted);
    on<OnlineToggled>(_onOnline);
    on<_OfferArrived>(_onOffer);
    on<_Ticked>(_onTick);
    on<OfferAccepted>(_onAccept);
    on<OfferDeclined>(_onDecline);
    on<ArrivedPressed>((e, emit) => _runMission(emit, (m) => _arrived(m.offer.id)));
    on<StartRequested>((e, emit) => _runMission(emit, (m) => _start(StartParams(missionId: m.offer.id, code: e.code))));
    on<PauseToggled>((e, emit) => _runMission(emit, _togglePause.call));
    on<PickupConfirmed>((e, emit) => _runMission(
          emit,
          (m) => _confirmPickup(PickupParams(mission: m, checked: e.checked, photoTaken: e.photoTaken)),
        ));
    on<CompleteRequested>((e, emit) => _finish(emit, (m) => _complete(m.offer.id)));
    on<HandoverConfirmed>((e, emit) => _finish(
          emit,
          (m) => _handover(HandoverParams(missionId: m.offer.id, code: e.code, collectedWith: e.collectedWith)),
        ));
    on<ReceiptClosed>(_onReceiptClosed);
  }

  final GetDriverDay _getDay;
  final GetFarePolicy _getPolicy;
  final SetOnline _setOnline;
  final WatchOffers _watchOffers;
  final AcceptMission _accept;
  final DeclineMission _decline;
  final MarkArrived _arrived;
  final StartTrip _start;
  final TogglePause _togglePause;
  final CompleteTrip _complete;
  final ConfirmPickup _confirmPickup;
  final ConfirmHandover _handover;
  final RateCustomer _rate;

  StreamSubscription<MissionOffer>? _offersSub;
  Timer? _ticker;

  Future<void> _onStarted(MissionsStarted e, Emitter<MissionsState> emit) async {
    emit(state.copyWith(status: LoadStatus.loading));
    final day = await _getDay(const NoParams());
    final policy = await _getPolicy(const NoParams());
    emit(state.copyWith(
      status: day.isOk ? LoadStatus.ready : LoadStatus.failure,
      day: day.valueOrNull,
      policy: policy.valueOrNull,
      failure: day.fold((f) => f, (_) => null),
    ));
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => add(_Ticked(DateTime.now())));
    if (state.online) _listenOffers();
  }

  void _listenOffers() {
    _offersSub ??= _watchOffers(const NoParams()).listen((o) => add(_OfferArrived(o)));
  }

  Future<void> _onOnline(OnlineToggled e, Emitter<MissionsState> emit) async {
    if (state.active != null && state.online) {
      emit(state.copyWith(failure: const ValidationFailure('Terminez la mission en cours avant de vous déconnecter.')));
      return;
    }
    emit(state.copyWith(busy: true));
    final r = await _setOnline(!state.online);
    final day = r.valueOrNull;
    emit(state.copyWith(busy: false, day: day, failure: r.fold((f) => f, (_) => null)));
    if (day == null) return;
    if (day.online) {
      _listenOffers();
    } else {
      await _offersSub?.cancel();
      _offersSub = null;
      emit(state.copyWith(clearOffer: true));
    }
  }

  void _onOffer(_OfferArrived e, Emitter<MissionsState> emit) {
    if (state.active != null || !state.online) return;
    emit(state.copyWith(offer: e.offer, offerRemaining: e.offer.acceptSeconds));
  }

  Future<void> _onTick(_Ticked e, Emitter<MissionsState> emit) async {
    final offer = state.offer;
    if (offer != null) {
      final left = state.offerRemaining - 1;
      if (left <= 0) {
        // Délai dépassé : la proposition part au partenaire suivant.
        emit(state.copyWith(now: e.now, clearOffer: true, offerRemaining: 0));
        await _decline(offer.id);
        return;
      }
      emit(state.copyWith(now: e.now, offerRemaining: left));
      return;
    }
    // Ne rafraîchit l'horloge que si un compteur est affiché.
    if (state.active != null) emit(state.copyWith(now: e.now));
  }

  Future<void> _onAccept(OfferAccepted e, Emitter<MissionsState> emit) async {
    final offer = state.offer;
    if (offer == null) return;
    emit(state.copyWith(busy: true));
    final r = await _accept(offer.id);
    emit(r.fold(
      (f) => state.copyWith(busy: false, clearOffer: true, failure: f),
      (m) => state.copyWith(busy: false, clearOffer: true, active: m, clearReceipt: true),
    ));
  }

  Future<void> _onDecline(OfferDeclined e, Emitter<MissionsState> emit) async {
    final offer = state.offer;
    if (offer == null) return;
    emit(state.copyWith(clearOffer: true));
    await _decline(offer.id);
  }

  Future<void> _runMission(
    Emitter<MissionsState> emit,
    Future<Result<ActiveMission>> Function(ActiveMission m) action,
  ) async {
    final m = state.active;
    if (m == null || state.busy) return;
    emit(state.copyWith(busy: true));
    final r = await action(m);
    emit(r.fold(
      (f) => state.copyWith(busy: false, failure: f),
      (updated) => state.copyWith(busy: false, active: updated, now: DateTime.now()),
    ));
  }

  Future<void> _finish(
    Emitter<MissionsState> emit,
    Future<Result<MissionReceipt>> Function(ActiveMission m) action,
  ) async {
    final m = state.active;
    if (m == null || state.busy) return;
    emit(state.copyWith(busy: true));
    final r = await action(m);
    final receipt = r.valueOrNull;
    if (receipt == null) {
      emit(state.copyWith(busy: false, failure: r.fold((f) => f, (_) => null)));
      return;
    }
    final day = state.day;
    emit(state.copyWith(
      busy: false,
      receipt: receipt,
      active: m.copyWith(stage: MissionStage.completed),
      day: day?.copyWith(earnings: day.earnings + receipt.net, missions: day.missions + 1),
    ));
  }

  Future<void> _onReceiptClosed(ReceiptClosed e, Emitter<MissionsState> emit) async {
    final m = state.active;
    if (m != null) await _rate(RateCustomerParams(missionId: m.offer.id, stars: e.stars));
    emit(state.copyWith(clearActive: true, clearReceipt: true));
  }

  @override
  Future<void> close() async {
    _ticker?.cancel();
    await _offersSub?.cancel();
    return super.close();
  }
}
