import 'package:wami_core/wami_core.dart';

import '../entities/order.dart';

abstract interface class RestaurantRepository {
  /// Commandes du jour (nouvelles, en cuisine, prêtes).
  Future<Result<List<FoodOrder>>> getOrders(String establishmentId);
  Future<Result<FoodOrder>> accept(String orderId, int prepMinutes);
  Future<Result<FoodOrder>> reject(String orderId, String reason);
  Future<Result<FoodOrder>> extend(String orderId);
  Future<Result<FoodOrder>> markReady(String orderId);

  Future<Result<RestaurantMenu>> getMenu(String establishmentId);
  Future<Result<MenuItem>> setAvailability(String itemId, bool available);
  Future<Result<bool>> setPaused(String establishmentId, bool paused);
}
