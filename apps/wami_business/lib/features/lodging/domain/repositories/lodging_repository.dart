import 'package:wami_core/wami_core.dart';

import '../entities/lodging.dart';

class DeskBookingRequest {
  const DeskBookingRequest({
    required this.establishmentId,
    required this.roomTypeId,
    required this.guestName,
    required this.checkIn,
    required this.checkOut,
  });

  final String establishmentId;
  final String roomTypeId;
  final String guestName;
  final DateTime checkIn;
  final DateTime checkOut;
}

abstract interface class LodgingRepository {
  Future<Result<Planning>> getPlanning(String establishmentId, DateTime start, int days);
  Future<Result<Booking>> confirm(String bookingId);
  Future<Result<Booking>> reject(String bookingId, String reason);
  Future<Result<Booking>> createDeskBooking(DeskBookingRequest request);
  Future<Result<Booking>> checkIn(String establishmentId, String code);
  Future<Result<List<RoomType>>> getRoomTypes(String establishmentId);
  Future<Result<RoomType>> updateRoomType(String establishmentId, RoomType type);
}
