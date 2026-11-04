import 'package:wami_core/wami_core.dart';

import '../entities/transport.dart';
import '../repositories/transport_repository.dart';

class DeparturesParams {
  const DeparturesParams(this.establishmentId, this.day);
  final String establishmentId;
  final DateTime day;
}

class GetDepartures implements UseCase<List<Departure>, DeparturesParams> {
  const GetDepartures(this._repo);
  final TransportRepository _repo;

  @override
  Future<Result<List<Departure>>> call(DeparturesParams p) => _repo.getDepartures(p.establishmentId, p.day);
}

class GetDeparture implements UseCase<Departure, String> {
  const GetDeparture(this._repo);
  final TransportRepository _repo;

  @override
  Future<Result<Departure>> call(String departureId) => _repo.getDeparture(departureId);
}

Seat? _seat(Departure d, int number) {
  for (final s in d.seats) {
    if (s.number == number) return s;
  }
  return null;
}

class SellSeatParams {
  const SellSeatParams(this.departure, this.seat, this.passengerName);
  final Departure departure;
  final int seat;
  final String passengerName;
}

/// Vente au guichet : seulement une place libre, sur un départ pas encore parti.
class SellSeat implements UseCase<Departure, SellSeatParams> {
  const SellSeat(this._repo);
  final TransportRepository _repo;

  @override
  Future<Result<Departure>> call(SellSeatParams p) async {
    if (p.departure.departed) return const Err(UnavailableFailure('Ce bus est déjà parti.'));
    if (_seat(p.departure, p.seat)?.state != SeatState.free) return const Err(UnavailableFailure('Cette place n’est plus libre.'));
    if (p.passengerName.trim().length < 2) return const Err(ValidationFailure('Indiquez le nom du voyageur.'));
    return _repo.sellSeat(p.departure.id, p.seat, p.passengerName.trim());
  }
}

class BlockSeatParams {
  const BlockSeatParams(this.departure, this.seat);
  final Departure departure;
  final int seat;
}

/// Bloquer (place du convoyeur, siège abîmé…) ou débloquer. Jamais une place vendue.
class ToggleSeatBlocked implements UseCase<Departure, BlockSeatParams> {
  const ToggleSeatBlocked(this._repo);
  final TransportRepository _repo;

  @override
  Future<Result<Departure>> call(BlockSeatParams p) async {
    final s = _seat(p.departure, p.seat);
    if (s == null || s.state.isSold) return const Err(ValidationFailure('Une place vendue ne peut pas être bloquée.'));
    return _repo.setSeatBlocked(p.departure.id, p.seat, s.state == SeatState.free);
  }
}

class BoardParams {
  const BoardParams(this.departure, this.ticketCode, {required this.now});
  final Departure departure;
  final String ticketCode;
  final DateTime now;
}

class BoardPassenger implements UseCase<Seat, BoardParams> {
  const BoardPassenger(this._repo);
  final TransportRepository _repo;

  @override
  Future<Result<Seat>> call(BoardParams p) async {
    if (!RegExp(r'^\d{6}$').hasMatch(p.ticketCode)) return const Err(ValidationFailure('Le billet porte un code à 6 chiffres.'));
    if (!p.departure.boardingOpen(p.now)) return const Err(ValidationFailure('L’embarquement n’est pas ouvert pour ce départ.'));
    return _repo.board(p.departure.id, p.ticketCode);
  }
}

class DelayParams {
  const DelayParams(this.departure, this.minutes);
  final Departure departure;
  final int minutes;
}

/// Signaler un retard : les voyageurs sont prévenus par l'app (à valider : SMS aussi ?).
class ReportDelay implements UseCase<Departure, DelayParams> {
  const ReportDelay(this._repo);
  final TransportRepository _repo;

  @override
  Future<Result<Departure>> call(DelayParams p) async {
    if (p.departure.departed) return const Err(ValidationFailure('Ce bus est déjà parti.'));
    if (p.minutes < DelayRules.minMinutes || p.minutes > DelayRules.maxMinutes) {
      return const Err(ValidationFailure('Retard entre ${DelayRules.minMinutes} min et ${DelayRules.maxMinutes ~/ 60} h.'));
    }
    return _repo.reportDelay(p.departure.id, p.minutes);
  }
}

class GetLines implements UseCase<List<BusLine>, String> {
  const GetLines(this._repo);
  final TransportRepository _repo;

  @override
  Future<Result<List<BusLine>>> call(String establishmentId) => _repo.getLines(establishmentId);
}

class LinePriceParams {
  const LinePriceParams(this.line, this.price);
  final BusLine line;
  final int price;
}

class UpdateLinePrice implements UseCase<BusLine, LinePriceParams> {
  const UpdateLinePrice(this._repo);
  final TransportRepository _repo;

  @override
  Future<Result<BusLine>> call(LinePriceParams p) async {
    if (p.price < 500) return const Err(ValidationFailure('Prix trop bas.'));
    // Les billets déjà vendus gardent leur prix (à valider côté serveur).
    return _repo.updateLinePrice(p.line.id, p.price);
  }
}
