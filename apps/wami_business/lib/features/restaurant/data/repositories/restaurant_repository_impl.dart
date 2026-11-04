import 'package:wami_core/wami_core.dart';

import '../../domain/entities/order.dart';
import '../../domain/repositories/restaurant_repository.dart';
import '../datasources/restaurant_data_sources.dart';

class RestaurantRepositoryImpl implements RestaurantRepository {
  const RestaurantRepositoryImpl(this._remote);
  final RestaurantRemoteDataSource _remote;

  @override
  Future<Result<List<FoodOrder>>> getOrders(String establishmentId) => guard(() => _remote.orders(establishmentId));

  @override
  Future<Result<FoodOrder>> accept(String orderId, int prepMinutes) => guard(() => _remote.accept(orderId, prepMinutes));

  @override
  Future<Result<FoodOrder>> reject(String orderId, String reason) => guard(() => _remote.reject(orderId, reason));

  @override
  Future<Result<FoodOrder>> extend(String orderId) => guard(() => _remote.extend(orderId));

  @override
  Future<Result<FoodOrder>> markReady(String orderId) => guard(() => _remote.markReady(orderId));

  @override
  Future<Result<RestaurantMenu>> getMenu(String establishmentId) => guard(() => _remote.menu(establishmentId));

  @override
  Future<Result<MenuItem>> setAvailability(String itemId, bool available) =>
      guard(() => _remote.setAvailability(itemId, available));

  @override
  Future<Result<bool>> setPaused(String establishmentId, bool paused) => guard(() => _remote.setPaused(establishmentId, paused));
}
