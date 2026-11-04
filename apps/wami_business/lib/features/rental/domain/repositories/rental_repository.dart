import 'package:wami_core/wami_core.dart';

import '../entities/rental.dart';

abstract interface class RentalRepository {
  Future<Result<List<Listing>>> getListings(String establishmentId);
  Future<Result<Listing>> setRented(String listingId, bool rented);
  Future<Result<List<VisitRequest>>> getVisits(String establishmentId);
  Future<Result<VisitRequest>> acceptVisit(String visitId);
  Future<Result<VisitRequest>> declineVisit(String visitId);
  Future<Result<VisitRequest>> proposeVisit(String visitId, DateTime slot);
  Future<Result<List<AvailabilityWindow>>> getAvailability(String establishmentId);
  Future<Result<List<AvailabilityWindow>>> saveAvailability(String establishmentId, List<AvailabilityWindow> windows);
}
