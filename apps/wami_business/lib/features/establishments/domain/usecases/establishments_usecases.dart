import 'package:wami_core/wami_core.dart';

import '../entities/establishment.dart';
import '../repositories/establishments_repository.dart';

class GetEstablishments implements UseCase<List<Establishment>, NoParams> {
  const GetEstablishments(this._repo);
  final EstablishmentsRepository _repo;

  @override
  Future<Result<List<Establishment>>> call(NoParams _) => _repo.getEstablishments();
}

class SetOpenParams {
  const SetOpenParams(this.establishment, this.open);
  final Establishment establishment;
  final bool open;
}

/// Ouvre ou ferme l'établissement aux nouvelles demandes.
/// Les commandes et réservations déjà acceptées restent dues.
class SetEstablishmentOpen implements UseCase<Establishment, SetOpenParams> {
  const SetEstablishmentOpen(this._repo);
  final EstablishmentsRepository _repo;

  @override
  Future<Result<Establishment>> call(SetOpenParams p) async {
    if (p.establishment.open == p.open) return Ok(p.establishment);
    return _repo.setOpen(p.establishment.id, p.open);
  }
}

class GetDashboard implements UseCase<DashboardSnapshot, String> {
  const GetDashboard(this._repo);
  final EstablishmentsRepository _repo;

  @override
  Future<Result<DashboardSnapshot>> call(String establishmentId) => _repo.getDashboard(establishmentId);
}
