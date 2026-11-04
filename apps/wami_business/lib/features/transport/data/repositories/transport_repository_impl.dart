import 'package:wami_core/wami_core.dart';

import '../../domain/entities/transport.dart';
import '../../domain/repositories/transport_repository.dart';
import '../datasources/transport_data_sources.dart';

class TransportRepositoryImpl implements TransportRepository {
  const TransportRepositoryImpl(this._remote);
  final TransportRemoteDataSource _remote;

  @override
  Future<Result<List<Departure>>> getDepartures(String establishmentId, DateTime day) =>
      guard(() => _remote.departures(establishmentId, day));

  @override
  Future<Result<Departure>> getDeparture(String departureId) => guard(() => _remote.departure(departureId));

  @override
  Future<Result<Departure>> sellSeat(String departureId, int seat, String passengerName) =>
      guard(() => _remote.sellSeat(departureId, seat, passengerName));

  @override
  Future<Result<Departure>> setSeatBlocked(String departureId, int seat, bool blocked) =>
      guard(() => _remote.setSeatBlocked(departureId, seat, blocked));

  @override
  Future<Result<Seat>> board(String departureId, String ticketCode) => guard(() => _remote.board(departureId, ticketCode));

  @override
  Future<Result<Departure>> reportDelay(String departureId, int minutes) => guard(() => _remote.reportDelay(departureId, minutes));

  @override
  Future<Result<List<BusLine>>> getLines(String establishmentId) => guard(() => _remote.lines(establishmentId));

  @override
  Future<Result<BusLine>> updateLinePrice(String lineId, int price) => guard(() => _remote.updateLinePrice(lineId, price));
}
