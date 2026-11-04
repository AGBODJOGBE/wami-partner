import 'package:wami_core/wami_core.dart';

import '../entities/history.dart';

abstract interface class HistoryRepository {
  /// Toutes les courses, de la plus récente à la plus ancienne (le serveur ne pagine pas).
  Future<Result<List<HistoryRide>>> getRides();
  Future<Result<List<HistoryDelivery>>> getDeliveries();
}
