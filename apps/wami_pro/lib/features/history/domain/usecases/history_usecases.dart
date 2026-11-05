import 'package:wami_core/wami_core.dart';

import '../entities/history.dart';
import '../repositories/history_repository.dart';

class GetRideHistory implements UseCase<List<HistoryRide>, NoParams> {
  const GetRideHistory(this._repo);
  final HistoryRepository _repo;

  @override
  Future<Result<List<HistoryRide>>> call(NoParams _) => _repo.getRides();
}

class GetDeliveryHistory implements UseCase<List<HistoryDelivery>, NoParams> {
  const GetDeliveryHistory(this._repo);
  final HistoryRepository _repo;

  @override
  Future<Result<List<HistoryDelivery>>> call(NoParams _) => _repo.getDeliveries();
}
