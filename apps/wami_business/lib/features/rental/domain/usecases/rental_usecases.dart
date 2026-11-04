import 'package:wami_core/wami_core.dart';

import '../entities/rental.dart';
import '../repositories/rental_repository.dart';

class GetListings implements UseCase<List<Listing>, String> {
  const GetListings(this._repo);
  final RentalRepository _repo;

  @override
  Future<Result<List<Listing>>> call(String establishmentId) => _repo.getListings(establishmentId);
}

class SetListingRented implements UseCase<Listing, Listing> {
  const SetListingRented(this._repo);
  final RentalRepository _repo;

  /// Bascule loué / disponible.
  @override
  Future<Result<Listing>> call(Listing l) => _repo.setRented(l.id, !l.rented);
}

class GetVisits implements UseCase<List<VisitRequest>, String> {
  const GetVisits(this._repo);
  final RentalRepository _repo;

  @override
  Future<Result<List<VisitRequest>>> call(String establishmentId) => _repo.getVisits(establishmentId);
}

class AcceptVisit implements UseCase<VisitRequest, VisitRequest> {
  const AcceptVisit(this._repo);
  final RentalRepository _repo;

  @override
  Future<Result<VisitRequest>> call(VisitRequest v) async {
    if (v.status != VisitStatus.pending) return const Err(UnavailableFailure('Demande déjà traitée.'));
    return _repo.acceptVisit(v.id);
  }
}

class DeclineVisit implements UseCase<VisitRequest, VisitRequest> {
  const DeclineVisit(this._repo);
  final RentalRepository _repo;

  @override
  Future<Result<VisitRequest>> call(VisitRequest v) async {
    if (v.status != VisitStatus.pending) return const Err(UnavailableFailure('Demande déjà traitée.'));
    return _repo.declineVisit(v.id);
  }
}

class ProposeVisitParams {
  const ProposeVisitParams({required this.visit, required this.slot, required this.windows, required this.now});
  final VisitRequest visit;
  final DateTime slot;
  final List<AvailabilityWindow> windows;
  final DateTime now;
}

/// Un autre créneau doit être dans le futur et dans les disponibilités déclarées.
class ProposeVisitSlot implements UseCase<VisitRequest, ProposeVisitParams> {
  const ProposeVisitSlot(this._repo);
  final RentalRepository _repo;

  @override
  Future<Result<VisitRequest>> call(ProposeVisitParams p) async {
    if (p.visit.status != VisitStatus.pending) return const Err(UnavailableFailure('Demande déjà traitée.'));
    if (!p.slot.isAfter(p.now)) return const Err(ValidationFailure('Choisissez un créneau à venir.'));
    if (!VisitSlots.fits(p.slot, p.windows)) {
      return const Err(ValidationFailure('Ce créneau est hors de vos disponibilités.'));
    }
    return _repo.proposeVisit(p.visit.id, p.slot);
  }
}

class GetAvailability implements UseCase<List<AvailabilityWindow>, String> {
  const GetAvailability(this._repo);
  final RentalRepository _repo;

  @override
  Future<Result<List<AvailabilityWindow>>> call(String establishmentId) => _repo.getAvailability(establishmentId);
}

class SaveAvailabilityParams {
  const SaveAvailabilityParams(this.establishmentId, this.windows);
  final String establishmentId;
  final List<AvailabilityWindow> windows;
}

class SaveAvailability implements UseCase<List<AvailabilityWindow>, SaveAvailabilityParams> {
  const SaveAvailability(this._repo);
  final RentalRepository _repo;

  @override
  Future<Result<List<AvailabilityWindow>>> call(SaveAvailabilityParams p) async {
    if (p.windows.any((w) => !w.isValid)) return const Err(ValidationFailure('Plage horaire invalide (entre 6 h et 21 h).'));
    for (var i = 0; i < p.windows.length; i++) {
      for (var j = i + 1; j < p.windows.length; j++) {
        final a = p.windows[i];
        final b = p.windows[j];
        if (a.weekday == b.weekday && a.startHour < b.endHour && b.startHour < a.endHour) {
          return Err(ValidationFailure('Deux plages se chevauchent le ${AvailabilityWindow.dayNames[a.weekday - 1].toLowerCase()}.'));
        }
      }
    }
    return _repo.saveAvailability(p.establishmentId, p.windows);
  }
}
