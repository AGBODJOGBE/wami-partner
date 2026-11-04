import 'package:wami_core/wami_core.dart';

import '../entities/transport.dart';

abstract interface class TransportRepository {
  Future<Result<List<Departure>>> getDepartures(String establishmentId, DateTime day);
  Future<Result<Departure>> getDeparture(String departureId);
  Future<Result<Departure>> sellSeat(String departureId, int seat, String passengerName);
  Future<Result<Departure>> setSeatBlocked(String departureId, int seat, bool blocked);
  Future<Result<Seat>> board(String departureId, String ticketCode);
  Future<Result<Departure>> reportDelay(String departureId, int minutes);
  Future<Result<List<BusLine>>> getLines(String establishmentId);
  Future<Result<BusLine>> updateLinePrice(String lineId, int price);
}
