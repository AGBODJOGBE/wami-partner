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

/// Déconnexion : arrête l'écoute et remet l'écran des missions à zéro.
final class MissionsReset extends MissionsEvent {
  const MissionsReset();
}

/// Le chauffeur annule la mission en cours (motif facultatif).
final class CancelRequested extends MissionsEvent {
  const CancelRequested([this.reason]);
  final String? reason;
  @override
  List<Object?> get props => [reason];
}

final class NoShowRequested extends MissionsEvent {
  const NoShowRequested();
}

final class FailureReported extends MissionsEvent {
  const FailureReported(this.reason);
  final String reason;
  @override
  List<Object?> get props => [reason];
}

final class ReturnStarted extends MissionsEvent {
  const ReturnStarted();
}

final class ReturnCompleted extends MissionsEvent {
  const ReturnCompleted();
}

final class DestinationAnswered extends MissionsEvent {
  const DestinationAnswered({required this.accept});
  final bool accept;
  @override
  List<Object?> get props => [accept];
}

/// Une course démarrée directement par le chauffeur (déjà créée côté serveur).
final class DirectRideBegan extends MissionsEvent {
  const DirectRideBegan(this.mission);
  final ActiveMission mission;
  @override
  List<Object?> get props => [mission];
}

final class _DestinationRequested extends MissionsEvent {
  const _DestinationRequested(this.change);
  final DestinationChange change;
  @override
  List<Object?> get props => [change];
}

final class _HotZone extends MissionsEvent {
  const _HotZone(this.label);
  final String? label;
  @override
  List<Object?> get props => [label];
}

final class _Cancelled extends MissionsEvent {
  const _Cancelled(this.missionId);
  final String missionId;
  @override
  List<Object?> get props => [missionId];
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
  const StartRequested([this.code = '']);
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
  const PickupConfirmed({required this.checked, required this.photoTaken, this.photoPath});
  final Set<String> checked;
  final bool photoTaken;
  final String? photoPath;
  @override
  List<Object?> get props => [checked, photoTaken, photoPath];
}

final class HandoverConfirmed extends MissionsEvent {
  const HandoverConfirmed({required this.code, required this.collectedWith, this.photoPath});
  final String code;
  final PaymentMode collectedWith;
  final String? photoPath;
  @override
  List<Object?> get props => [code, collectedWith, photoPath];
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
    this.destinationChange,
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

  /// Demande de changement de destination en attente de réponse.
  final DestinationChange? destinationChange;
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
    DestinationChange? destinationChange,
    bool clearDestinationChange = false,
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
      destinationChange: clearDestinationChange ? null : (destinationChange ?? this.destinationChange),
      busy: busy ?? this.busy,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [status, day, policy, offer, offerRemaining, active, now, receipt, destinationChange, busy, failure];
}

// ─── Bloc ────────────────────────────────────────────────────────────────────

/// Cœur de WAMI Pro : disponibilité, propositions, mission en cours.
class MissionsBloc extends Bloc<MissionsEvent, MissionsState> {
  MissionsBloc({
    required GetDriverDay getDay,
    required GetFarePolicy getPolicy,
    required SetOnline setOnline,
    required WatchOffers watchOffers,
    required GetCurrentMission currentMission,
    required WatchCancellations watchCancellations,
    required CancelMission cancel,
    required DeclareNoShow noShow,
    required ReportDeliveryFailure reportFailure,
    required StartReturn startReturn,
    required CompleteReturn completeReturn,
    required WatchDestinationChanges watchDestinationChanges,
    required AnswerDestinationChange answerDestination,
    required WatchHotZones watchHotZones,
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
        _currentMission = currentMission,
        _watchCancellations = watchCancellations,
        _cancel = cancel,
        _noShow = noShow,
        _reportFailure = reportFailure,
        _startReturn = startReturn,
        _completeReturn = completeReturn,
        _watchDestinationChanges = watchDestinationChanges,
        _answerDestination = answerDestination,
        _watchHotZones = watchHotZones,
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
    on<MissionsReset>(_onReset);
    on<_Cancelled>(_onCancelled);
    on<CancelRequested>((e, emit) => _closeMission(emit, (m) => _cancel(CancelParams(missionId: m.offer.id, reason: e.reason))));
    on<NoShowRequested>((e, emit) => _closeMission(emit, (m) => _noShow(m.offer.id)));
    on<ReturnCompleted>((e, emit) => _closeMission(emit, (m) => _completeReturn(m.offer.id)));
    on<FailureReported>((e, emit) => _runMission(emit, (m) => _reportFailure(FailureParams(missionId: m.offer.id, reason: e.reason))));
    on<ReturnStarted>((e, emit) => _runMission(emit, (m) => _startReturn(m.offer.id)));
    on<DestinationAnswered>(_onDestinationAnswered);
    on<DirectRideBegan>((e, emit) => emit(state.copyWith(active: e.mission, clearReceipt: true, now: DateTime.now())));
    on<_DestinationRequested>((e, emit) => emit(state.copyWith(destinationChange: e.change)));
    on<_HotZone>((e, emit) {
      final d = state.day;
      if (d != null) emit(state.copyWith(day: e.label == null ? d.copyWith(clearHotZone: true) : d.copyWith(hotZone: e.label)));
    });
    on<_OfferArrived>(_onOffer);
    on<_Ticked>(_onTick);
    on<OfferAccepted>(_onAccept);
    on<OfferDeclined>(_onDecline);
    on<ArrivedPressed>((e, emit) => _runMission(emit, (m) => _arrived(m.offer.id)));
    on<StartRequested>((e, emit) => _runMission(emit, (m) => _start(StartParams(missionId: m.offer.id, code: e.code))));
    on<PauseToggled>((e, emit) => _runMission(emit, _togglePause.call));
    on<PickupConfirmed>((e, emit) => _runMission(
          emit,
          (m) => _confirmPickup(
            PickupParams(mission: m, checked: e.checked, photoTaken: e.photoTaken, photoPath: e.photoPath),
          ),
        ));
    on<CompleteRequested>((e, emit) => _finish(emit, (m) => _complete(m.offer.id)));
    on<HandoverConfirmed>((e, emit) => _finish(
          emit,
          (m) => _handover(
            HandoverParams(missionId: m.offer.id, code: e.code, collectedWith: e.collectedWith, photoPath: e.photoPath),
          ),
        ));
    on<ReceiptClosed>(_onReceiptClosed);
  }

  final GetDriverDay _getDay;
  final GetFarePolicy _getPolicy;
  final SetOnline _setOnline;
  final WatchOffers _watchOffers;
  final GetCurrentMission _currentMission;
  final WatchCancellations _watchCancellations;
  final CancelMission _cancel;
  final DeclareNoShow _noShow;
  final ReportDeliveryFailure _reportFailure;
  final StartReturn _startReturn;
  final CompleteReturn _completeReturn;
  final WatchDestinationChanges _watchDestinationChanges;
  final AnswerDestinationChange _answerDestination;
  final WatchHotZones _watchHotZones;
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
  StreamSubscription<String>? _cancelSub;
  StreamSubscription<DestinationChange>? _destSub;
  StreamSubscription<String?>? _hotSub;
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
    _cancelSub ??= _watchCancellations(const NoParams()).listen((id) => add(_Cancelled(id)));
    _destSub ??= _watchDestinationChanges(const NoParams()).listen((c) => add(_DestinationRequested(c)));
    _hotSub ??= _watchHotZones(const NoParams()).listen((z) => add(_HotZone(z)));
    if (state.online) _listenOffers();

    // Reprise d'une mission interrompue (app fermée en cours de course).
    final current = await _currentMission(const NoParams());
    final mission = current.valueOrNull;
    if (mission != null && state.active == null) emit(state.copyWith(active: mission, now: DateTime.now()));
  }

  Future<void> _onReset(MissionsReset e, Emitter<MissionsState> emit) async {
    await _offersSub?.cancel();
    await _cancelSub?.cancel();
    await _destSub?.cancel();
    await _hotSub?.cancel();
    _offersSub = _cancelSub = _destSub = _hotSub = null;
    emit(MissionsState());
  }

  void _onCancelled(_Cancelled e, Emitter<MissionsState> emit) {
    final m = state.active;
    if (m == null || m.offer.id != e.missionId || m.stage == MissionStage.completed) return;
    emit(state.copyWith(
      clearActive: true,
      clearReceipt: true,
      failure: const ValidationFailure('Le client a annulé la mission.'),
    ));
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

  /// Action qui met fin à la mission sans reçu (annulation, client absent, retour du colis).
  Future<void> _closeMission(
    Emitter<MissionsState> emit,
    Future<Result<void>> Function(ActiveMission m) action,
  ) async {
    final m = state.active;
    if (m == null || state.busy) return;
    emit(state.copyWith(busy: true));
    final r = await action(m);
    emit(r.isOk
        ? state.copyWith(busy: false, clearActive: true, clearReceipt: true, clearDestinationChange: true)
        : state.copyWith(busy: false, failure: r.fold((f) => f, (_) => null)));
  }

  Future<void> _onDestinationAnswered(DestinationAnswered e, Emitter<MissionsState> emit) async {
    final m = state.active;
    if (m == null) return;
    emit(state.copyWith(clearDestinationChange: true, busy: true));
    final r = await _answerDestination(AnswerParams(missionId: m.offer.id, accept: e.accept));
    emit(r.fold(
      (f) => state.copyWith(busy: false, failure: f),
      (updated) => state.copyWith(busy: false, active: updated),
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
    await _cancelSub?.cancel();
    await _destSub?.cancel();
    await _hotSub?.cancel();
    return super.close();
  }
}
