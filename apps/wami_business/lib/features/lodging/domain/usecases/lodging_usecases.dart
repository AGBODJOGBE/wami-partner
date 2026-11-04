import 'package:wami_core/wami_core.dart';

import '../entities/lodging.dart';
import '../repositories/lodging_repository.dart';

class PlanningParams {
  const PlanningParams(this.establishmentId, this.start, {this.days = 7});
  final String establishmentId;
  final DateTime start;
  final int days;
}

class GetPlanning implements UseCase<Planning, PlanningParams> {
  const GetPlanning(this._repo);
  final LodgingRepository _repo;

  @override
  Future<Result<Planning>> call(PlanningParams p) => _repo.getPlanning(p.establishmentId, dateOnly(p.start), p.days);
}

class ConfirmBooking implements UseCase<Booking, Booking> {
  const ConfirmBooking(this._repo);
  final LodgingRepository _repo;

  @override
  Future<Result<Booking>> call(Booking b) async {
    if (b.status != BookingStatus.pending) return const Err(UnavailableFailure('Cette demande a déjà été traitée.'));
    return _repo.confirm(b.id);
  }
}

class RejectBookingParams {
  const RejectBookingParams(this.booking, this.reason);
  final Booking booking;
  final String reason;
}

class RejectBooking implements UseCase<Booking, RejectBookingParams> {
  const RejectBooking(this._repo);
  final LodgingRepository _repo;

  @override
  Future<Result<Booking>> call(RejectBookingParams p) async {
    if (p.booking.status != BookingStatus.pending) return const Err(UnavailableFailure('Cette demande a déjà été traitée.'));
    if (p.reason.trim().isEmpty) return const Err(ValidationFailure('Choisissez un motif.'));
    return _repo.reject(p.booking.id, p.reason.trim());
  }
}

/// Réservation prise au comptoir : mêmes règles que l'app, pour ne jamais surbooker.
class CreateDeskBooking implements UseCase<Booking, DeskBookingRequest> {
  CreateDeskBooking(this._repo, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;
  final LodgingRepository _repo;
  final DateTime Function() _clock;

  @override
  Future<Result<Booking>> call(DeskBookingRequest r) async {
    if (r.guestName.trim().length < 2) return const Err(ValidationFailure('Indiquez le nom du client.'));
    final from = dateOnly(r.checkIn);
    final to = dateOnly(r.checkOut);
    if (from.isBefore(dateOnly(_clock()))) return const Err(ValidationFailure('L’arrivée ne peut pas être dans le passé.'));
    if (!to.isAfter(from)) return const Err(ValidationFailure('Au moins une nuit.'));

    final nights = to.difference(from).inDays;
    final planning = await _repo.getPlanning(r.establishmentId, from, nights);
    switch (planning) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        RoomType? type;
        for (final t in value.roomTypes) {
          if (t.id == r.roomTypeId) type = t;
        }
        if (type == null) return const Err(UnavailableFailure());
        if (StayRules.freeUnits(type, value.bookings, from, to) <= 0) {
          return const Err(UnavailableFailure('Plus de chambre libre de ce type sur ces dates.'));
        }
        return _repo.createDeskBooking(r);
    }
  }
}

/// Check-in : le client présente le code à 6 chiffres reçu dans l'app.
class CheckInGuestParams {
  const CheckInGuestParams(this.establishmentId, this.code);
  final String establishmentId;
  final String code;
}

class CheckInGuest implements UseCase<Booking, CheckInGuestParams> {
  const CheckInGuest(this._repo);
  final LodgingRepository _repo;

  @override
  Future<Result<Booking>> call(CheckInGuestParams p) async {
    if (!RegExp(r'^\d{6}$').hasMatch(p.code)) return const Err(ValidationFailure('Le code contient 6 chiffres.'));
    return _repo.checkIn(p.establishmentId, p.code);
  }
}

class GetRoomTypes implements UseCase<List<RoomType>, String> {
  const GetRoomTypes(this._repo);
  final LodgingRepository _repo;

  @override
  Future<Result<List<RoomType>>> call(String establishmentId) => _repo.getRoomTypes(establishmentId);
}

class UpdateRoomTypeParams {
  const UpdateRoomTypeParams(this.establishmentId, this.type);
  final String establishmentId;
  final RoomType type;
}

class UpdateRoomType implements UseCase<RoomType, UpdateRoomTypeParams> {
  const UpdateRoomType(this._repo);
  final LodgingRepository _repo;

  /// Prix plancher (à valider avec l'équipe commerciale).
  static const minPrice = 2000;

  @override
  Future<Result<RoomType>> call(UpdateRoomTypeParams p) async {
    final t = p.type;
    if (t.nightlyPrice < minPrice) return Err(ValidationFailure('Prix minimum : ${Fmt.fcfa(minPrice)} la nuit.'));
    if (t.openUnits < 0 || t.openUnits > t.units) {
      return Err(ValidationFailure('Entre 0 et ${t.units} chambres ouvertes.'));
    }
    return _repo.updateRoomType(p.establishmentId, t);
  }
}
