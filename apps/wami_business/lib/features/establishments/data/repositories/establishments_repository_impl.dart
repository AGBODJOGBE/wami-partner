import 'package:wami_core/wami_core.dart';

import '../../domain/entities/establishment.dart';
import '../../domain/repositories/establishments_repository.dart';
import '../datasources/establishments_data_sources.dart';

class EstablishmentsRepositoryImpl implements EstablishmentsRepository {
  const EstablishmentsRepositoryImpl(this._remote);
  final EstablishmentsRemoteDataSource _remote;

  @override
  Future<Result<List<Establishment>>> getEstablishments() => guard(_remote.establishments);

  @override
  Future<Result<Establishment>> setOpen(String establishmentId, bool open) =>
      guard(() => _remote.setOpen(establishmentId, open));

  @override
  Future<Result<DashboardSnapshot>> getDashboard(String establishmentId) =>
      guard(() => _remote.dashboard(establishmentId));
}
