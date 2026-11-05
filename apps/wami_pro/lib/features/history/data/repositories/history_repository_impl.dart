import 'package:wami_core/wami_core.dart';

import '../../domain/entities/history.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_data_sources.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  const HistoryRepositoryImpl(this._remote);
  final HistoryRemoteDataSource _remote;

  @override
  Future<Result<List<HistoryRide>>> getRides() => guard(_remote.rides);

  @override
  Future<Result<List<HistoryDelivery>>> getDeliveries() => guard(_remote.deliveries);
}
