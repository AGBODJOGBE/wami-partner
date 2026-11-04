import 'package:wami_core/wami_core.dart';

import '../../domain/entities/rental.dart';
import '../../domain/repositories/rental_repository.dart';
import '../datasources/rental_data_sources.dart';

class RentalRepositoryImpl implements RentalRepository {
  const RentalRepositoryImpl(this._remote);
  final RentalRemoteDataSource _remote;

  @override
  Future<Result<List<Listing>>> getListings(String establishmentId) => guard(() => _remote.listings(establishmentId));

  @override
  Future<Result<Listing>> setRented(String listingId, bool rented) => guard(() => _remote.setRented(listingId, rented));

  @override
  Future<Result<List<VisitRequest>>> getVisits(String establishmentId) => guard(() => _remote.visits(establishmentId));

  @override
  Future<Result<VisitRequest>> acceptVisit(String visitId) => guard(() => _remote.acceptVisit(visitId));

  @override
  Future<Result<VisitRequest>> declineVisit(String visitId) => guard(() => _remote.declineVisit(visitId));

  @override
  Future<Result<VisitRequest>> proposeVisit(String visitId, DateTime slot) => guard(() => _remote.proposeVisit(visitId, slot));

  @override
  Future<Result<List<AvailabilityWindow>>> getAvailability(String establishmentId) =>
      guard(() => _remote.availability(establishmentId));

  @override
  Future<Result<List<AvailabilityWindow>>> saveAvailability(String establishmentId, List<AvailabilityWindow> windows) =>
      guard(() => _remote.saveAvailability(establishmentId, windows));
}
