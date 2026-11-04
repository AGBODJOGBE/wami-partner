import 'package:wami_core/wami_core.dart';

import '../entities/order.dart';
import '../repositories/restaurant_repository.dart';

class GetOrders implements UseCase<List<FoodOrder>, String> {
  const GetOrders(this._repo);
  final RestaurantRepository _repo;

  @override
  Future<Result<List<FoodOrder>>> call(String establishmentId) => _repo.getOrders(establishmentId);
}

class AcceptParams {
  const AcceptParams(this.order, this.prepMinutes);
  final FoodOrder order;
  final int prepMinutes;
}

/// Accepter = s'engager sur un temps de préparation, transmis au client et au livreur.
class AcceptOrder implements UseCase<FoodOrder, AcceptParams> {
  const AcceptOrder(this._repo);
  final RestaurantRepository _repo;

  @override
  Future<Result<FoodOrder>> call(AcceptParams p) async {
    if (p.order.status != OrderStatus.incoming) return const Err(UnavailableFailure('Cette commande a déjà été traitée.'));
    if (p.prepMinutes < PrepRules.minMinutes || p.prepMinutes > PrepRules.maxMinutes) {
      return const Err(ValidationFailure('Temps de préparation entre ${PrepRules.minMinutes} et ${PrepRules.maxMinutes} min.'));
    }
    return _repo.accept(p.order.id, p.prepMinutes);
  }
}

class RejectParams {
  const RejectParams(this.order, this.reason);
  final FoodOrder order;
  final String reason;
}

/// Refuser exige un motif : le client est prévenu et remboursé.
class RejectOrder implements UseCase<FoodOrder, RejectParams> {
  const RejectOrder(this._repo);
  final RestaurantRepository _repo;

  @override
  Future<Result<FoodOrder>> call(RejectParams p) async {
    if (p.order.status != OrderStatus.incoming) return const Err(UnavailableFailure('Cette commande a déjà été traitée.'));
    if (p.reason.trim().isEmpty) return const Err(ValidationFailure('Choisissez un motif de refus.'));
    return _repo.reject(p.order.id, p.reason.trim());
  }
}

/// « +5 min » : limité pour ne pas faire attendre le livreur indéfiniment.
class ExtendPrep implements UseCase<FoodOrder, FoodOrder> {
  const ExtendPrep(this._repo);
  final RestaurantRepository _repo;

  @override
  Future<Result<FoodOrder>> call(FoodOrder order) async {
    if (!order.canExtend) {
      return const Err(ValidationFailure('Délai déjà prolongé ${PrepRules.maxExtensions} fois.'));
    }
    return _repo.extend(order.id);
  }
}

class MarkOrderReady implements UseCase<FoodOrder, FoodOrder> {
  const MarkOrderReady(this._repo);
  final RestaurantRepository _repo;

  @override
  Future<Result<FoodOrder>> call(FoodOrder order) async {
    if (order.status != OrderStatus.kitchen) return const Err(ValidationFailure('La commande n’est pas en cuisine.'));
    return _repo.markReady(order.id);
  }
}

class GetMenu implements UseCase<RestaurantMenu, String> {
  const GetMenu(this._repo);
  final RestaurantRepository _repo;

  @override
  Future<Result<RestaurantMenu>> call(String establishmentId) => _repo.getMenu(establishmentId);
}

class AvailabilityParams {
  const AvailabilityParams(this.item, this.available);
  final MenuItem item;
  final bool available;
}

class SetItemAvailability implements UseCase<MenuItem, AvailabilityParams> {
  const SetItemAvailability(this._repo);
  final RestaurantRepository _repo;

  @override
  Future<Result<MenuItem>> call(AvailabilityParams p) => _repo.setAvailability(p.item.id, p.available);
}

class PauseParams {
  const PauseParams(this.establishmentId, this.paused);
  final String establishmentId;
  final bool paused;
}

class SetOrdersPaused implements UseCase<bool, PauseParams> {
  const SetOrdersPaused(this._repo);
  final RestaurantRepository _repo;

  @override
  Future<Result<bool>> call(PauseParams p) => _repo.setPaused(p.establishmentId, p.paused);
}
