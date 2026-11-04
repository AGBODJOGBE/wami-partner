import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wami_core/wami_core.dart';
import 'package:wami_business/features/restaurant/domain/entities/order.dart';
import 'package:wami_business/features/restaurant/domain/repositories/restaurant_repository.dart';
import 'package:wami_business/features/restaurant/domain/usecases/restaurant_usecases.dart';

class _Repo extends Mock implements RestaurantRepository {}

final _placed = DateTime(2026, 11, 4, 12);

FoodOrder _order({OrderStatus status = OrderStatus.incoming, int extensions = 0}) => FoodOrder(
      id: 'o1',
      number: '#A-1',
      customerName: 'X',
      lines: const [OrderLine(name: 'Plat', quantity: 2, unitPrice: 1500)],
      placedAt: _placed,
      status: status,
      prepMinutes: 15,
      acceptedAt: _placed,
      extensions: extensions,
    );

void main() {
  late _Repo repo;
  setUp(() => repo = _Repo());

  test('total et heure promise (prolongations comprises)', () {
    final o = _order(status: OrderStatus.kitchen, extensions: 1);
    expect(o.total, 3000);
    expect(o.dueAt, _placed.add(const Duration(minutes: 20)));
    expect(o.remainingSeconds(_placed.add(const Duration(minutes: 21))), -60);
  });

  test('temps de préparation hors bornes refusé', () async {
    final r = await AcceptOrder(repo)(AcceptParams(_order(), 120));
    expect((r as Err<FoodOrder>).failure, isA<ValidationFailure>());
    verifyNever(() => repo.accept('o1', 120));
  });

  test('une commande déjà en cuisine ne peut pas être refusée', () async {
    final r = await RejectOrder(repo)(RejectParams(_order(status: OrderStatus.kitchen), 'Rupture'));
    expect((r as Err<FoodOrder>).failure, isA<UnavailableFailure>());
  });

  test('« +5 min » limité', () async {
    final r = await ExtendPrep(repo)(_order(status: OrderStatus.kitchen, extensions: PrepRules.maxExtensions));
    expect(r.isOk, isFalse);
  });
}
