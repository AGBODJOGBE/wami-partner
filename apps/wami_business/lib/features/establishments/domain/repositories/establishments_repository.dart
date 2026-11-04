import 'package:wami_core/wami_core.dart';

import '../entities/establishment.dart';

abstract interface class EstablishmentsRepository {
  Future<Result<List<Establishment>>> getEstablishments();
  Future<Result<Establishment>> setOpen(String establishmentId, bool open);
  Future<Result<DashboardSnapshot>> getDashboard(String establishmentId);
}
