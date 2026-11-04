import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/data_state.dart';
import '../../domain/entities/lodging.dart';
import '../../domain/repositories/lodging_repository.dart';
import '../../domain/usecases/lodging_usecases.dart';

/// Planning de la semaine + demandes à confirmer.
class PlanningCubit extends Cubit<DataState<Planning>> {
  PlanningCubit(this._get, this._confirm, this._reject) : super(const DataState());
  final GetPlanning _get;
  final ConfirmBooking _confirm;
  final RejectBooking _reject;
  late String _establishmentId;
  DateTime _start = dateOnly(DateTime.now());

  Future<void> load(String establishmentId) async {
    _establishmentId = establishmentId;
    await reload();
  }

  Future<void> reload() async {
    emit(state.loading());
    emit(state.apply(await _get(PlanningParams(_establishmentId, _start))));
  }

  /// Semaine précédente (-1) ou suivante (+1). Jamais avant aujourd'hui.
  Future<void> shiftWeek(int direction) async {
    final today = dateOnly(DateTime.now());
    final next = DateTime(_start.year, _start.month, _start.day + 7 * direction);
    _start = next.isBefore(today) ? today : next;
    await reload();
  }

  Future<void> confirm(Booking b) => _act(_confirm(b));
  Future<void> reject(Booking b, String reason) => _act(_reject(RejectBookingParams(b, reason)));

  Future<void> _act(Future<Result<Booking>> action) async {
    final p = state.data;
    if (p == null) return;
    emit(state.working());
    final r = await action;
    r.fold(
      (f) => emit(state.failed(f)),
      (b) => emit(state.ready(Planning(
        start: p.start,
        days: p.days,
        roomTypes: p.roomTypes,
        bookings: [for (final x in p.bookings) x.id == b.id ? b : x],
      ))),
    );
  }
}

class RoomTypesCubit extends Cubit<DataState<List<RoomType>>> {
  RoomTypesCubit(this._get, this._update) : super(const DataState());
  final GetRoomTypes _get;
  final UpdateRoomType _update;
  late String _establishmentId;

  Future<void> load(String establishmentId) async {
    _establishmentId = establishmentId;
    emit(state.loading());
    emit(state.apply(await _get(establishmentId)));
  }

  Future<bool> save(RoomType t) async {
    final list = state.data ?? const <RoomType>[];
    emit(state.working());
    final r = await _update(UpdateRoomTypeParams(_establishmentId, t));
    r.fold(
      (f) => emit(state.failed(f)),
      (saved) => emit(state.ready([for (final x in list) x.id == saved.id ? saved : x])),
    );
    return r.isOk;
  }
}

class DeskBookingState extends Equatable {
  const DeskBookingState({
    this.types = const [],
    this.typeId,
    this.guestName = '',
    required this.checkIn,
    this.nights = 1,
    this.busy = false,
    this.failure,
    this.created,
  });

  final List<RoomType> types;
  final String? typeId;
  final String guestName;
  final DateTime checkIn;
  final int nights;
  final bool busy;
  final Failure? failure;
  final Booking? created;

  RoomType? get type {
    for (final t in types) {
      if (t.id == typeId) return t;
    }
    return null;
  }

  DateTime get checkOut => DateTime(checkIn.year, checkIn.month, checkIn.day + nights);
  int get total => (type?.nightlyPrice ?? 0) * nights;

  DeskBookingState copyWith({
    List<RoomType>? types,
    String? typeId,
    String? guestName,
    DateTime? checkIn,
    int? nights,
    bool? busy,
    Failure? failure,
    Booking? created,
  }) {
    return DeskBookingState(
      types: types ?? this.types,
      typeId: typeId ?? this.typeId,
      guestName: guestName ?? this.guestName,
      checkIn: checkIn ?? this.checkIn,
      nights: nights ?? this.nights,
      busy: busy ?? this.busy,
      failure: failure,
      created: created ?? this.created,
    );
  }

  @override
  List<Object?> get props => [types, typeId, guestName, checkIn, nights, busy, failure, created];
}

/// Réservation au comptoir (client sans l'app, appel téléphonique…).
class DeskBookingCubit extends Cubit<DeskBookingState> {
  DeskBookingCubit(this._getTypes, this._create) : super(DeskBookingState(checkIn: dateOnly(DateTime.now())));
  final GetRoomTypes _getTypes;
  final CreateDeskBooking _create;
  late String _establishmentId;

  Future<void> load(String establishmentId) async {
    _establishmentId = establishmentId;
    final r = await _getTypes(establishmentId);
    r.fold(
      (f) => emit(state.copyWith(failure: f)),
      (types) => emit(state.copyWith(types: types, typeId: types.firstOrNull?.id)),
    );
  }

  void selectType(String id) => emit(state.copyWith(typeId: id));
  void setGuest(String v) => emit(state.copyWith(guestName: v));
  void setCheckIn(DateTime d) => emit(state.copyWith(checkIn: dateOnly(d)));
  void setNights(int n) => emit(state.copyWith(nights: n));

  Future<void> submit() async {
    final typeId = state.typeId;
    if (typeId == null) return;
    emit(state.copyWith(busy: true));
    final r = await _create(DeskBookingRequest(
      establishmentId: _establishmentId,
      roomTypeId: typeId,
      guestName: state.guestName,
      checkIn: state.checkIn,
      checkOut: state.checkOut,
    ));
    r.fold(
      (f) => emit(state.copyWith(busy: false, failure: f)),
      (b) => emit(state.copyWith(busy: false, created: b)),
    );
  }
}

class CheckInCubit extends Cubit<DataState<Booking>> {
  CheckInCubit(this._checkIn) : super(const DataState());
  final CheckInGuest _checkIn;

  Future<void> submit(String establishmentId, String code) async {
    emit(state.working());
    emit(state.apply(await _checkIn(CheckInGuestParams(establishmentId, code))));
  }
}
