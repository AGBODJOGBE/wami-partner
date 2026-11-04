import 'package:wami_core/wami_core.dart';

import '../../domain/entities/lodging.dart';
import '../../domain/repositories/lodging_repository.dart';
import '../datasources/lodging_data_sources.dart';

class LodgingRepositoryImpl implements LodgingRepository {
  const LodgingRepositoryImpl(this._remote);
  final LodgingRemoteDataSource _remote;

  @override
  Future<Result<Planning>> getPlanning(String establishmentId, DateTime start, int days) =>
      guard(() => _remote.planning(establishmentId, start, days));

  @override
  Future<Result<Booking>> confirm(String bookingId) => guard(() => _remote.confirm(bookingId));

  @override
  Future<Result<Booking>> reject(String bookingId, String reason) => guard(() => _remote.reject(bookingId, reason));

  @override
  Future<Result<Booking>> createDeskBooking(DeskBookingRequest request) => guard(() => _remote.createDeskBooking(request));

  @override
  Future<Result<Booking>> checkIn(String establishmentId, String code) => guard(() => _remote.checkIn(establishmentId, code));

  @override
  Future<Result<List<RoomType>>> getRoomTypes(String establishmentId) => guard(() => _remote.roomTypes(establishmentId));

  @override
  Future<Result<RoomType>> updateRoomType(String establishmentId, RoomType type) =>
      guard(() => _remote.updateRoomType(establishmentId, type));
}
