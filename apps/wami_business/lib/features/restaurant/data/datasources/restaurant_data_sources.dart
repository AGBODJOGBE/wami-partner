import 'package:wami_core/wami_core.dart';

import '../../domain/entities/order.dart';

abstract interface class RestaurantRemoteDataSource {
  Future<List<FoodOrder>> orders(String establishmentId);
  Future<FoodOrder> accept(String orderId, int prepMinutes);
  Future<FoodOrder> reject(String orderId, String reason);
  Future<FoodOrder> extend(String orderId);
  Future<FoodOrder> markReady(String orderId);
  Future<RestaurantMenu> menu(String establishmentId);
  Future<MenuItem> setAvailability(String itemId, bool available);
  Future<bool> setPaused(String establishmentId, bool paused);
}

FoodOrder _order(Map<String, dynamic> j) {
  DateTime? date(String k) => j[k] == null ? null : DateTime.parse(j[k] as String);
  return FoodOrder(
    id: j['id'] as String,
    number: j['number'] as String,
    customerName: j['customer_name'] as String,
    lines: [
      for (final l in (j['lines'] as List<dynamic>).cast<Map<String, dynamic>>())
        OrderLine(name: l['name'] as String, quantity: l['quantity'] as int, unitPrice: l['unit_price'] as int, note: l['note'] as String?),
    ],
    placedAt: DateTime.parse(j['placed_at'] as String),
    status: OrderStatus.values.byName(j['status'] as String),
    prepMinutes: j['prep_minutes'] as int?,
    acceptedAt: date('accepted_at'),
    extensions: j['extensions'] as int? ?? 0,
    readyAt: date('ready_at'),
    courierName: j['courier_name'] as String?,
    rejectReason: j['reject_reason'] as String?,
  );
}

MenuItem _item(Map<String, dynamic> j) => MenuItem(
      id: j['id'] as String,
      name: j['name'] as String,
      category: j['category'] as String,
      price: j['price'] as int,
      available: j['available'] as bool? ?? true,
    );

/// Endpoints à valider. À terme, les nouvelles commandes devraient arriver
/// par notification push ou WebSocket plutôt que par relecture périodique.
class RestaurantApiDataSource implements RestaurantRemoteDataSource {
  const RestaurantApiDataSource(this._api);
  final ApiClient _api;

  @override
  Future<List<FoodOrder>> orders(String establishmentId) async {
    final j = await _api.get('/v1/business/establishments/$establishmentId/orders', query: {'scope': 'today'});
    return [for (final o in (j['items'] as List<dynamic>).cast<Map<String, dynamic>>()) _order(o)];
  }

  @override
  Future<FoodOrder> accept(String orderId, int prepMinutes) async =>
      _order(await _api.post('/v1/business/orders/$orderId/accept', body: {'prep_minutes': prepMinutes}));

  @override
  Future<FoodOrder> reject(String orderId, String reason) async =>
      _order(await _api.post('/v1/business/orders/$orderId/reject', body: {'reason': reason}));

  @override
  Future<FoodOrder> extend(String orderId) async => _order(await _api.post('/v1/business/orders/$orderId/extend'));

  @override
  Future<FoodOrder> markReady(String orderId) async => _order(await _api.post('/v1/business/orders/$orderId/ready'));

  @override
  Future<RestaurantMenu> menu(String establishmentId) async {
    final j = await _api.get('/v1/business/establishments/$establishmentId/menu');
    return RestaurantMenu(
      items: [for (final i in (j['items'] as List<dynamic>).cast<Map<String, dynamic>>()) _item(i)],
      paused: j['paused'] as bool? ?? false,
      hours: j['hours'] as String? ?? '',
    );
  }

  @override
  Future<MenuItem> setAvailability(String itemId, bool available) async =>
      _item(await _api.put('/v1/business/menu-items/$itemId', body: {'available': available}));

  @override
  Future<bool> setPaused(String establishmentId, bool paused) async {
    final j = await _api.put('/v1/business/establishments/$establishmentId/pause', body: {'paused': paused});
    return j['paused'] as bool? ?? paused;
  }
}

/// Démo : une nouvelle commande arrive toutes les 20 s (3 au plus en attente) ;
/// une commande prête est récupérée par un livreur 8 s plus tard.
class RestaurantFakeDataSource implements RestaurantRemoteDataSource {
  RestaurantFakeDataSource(this._fake) {
    final now = DateTime.now();
    _orders.addAll([
      FoodOrder(
        id: 'o1',
        number: '#A-214',
        customerName: 'Afiavi K.',
        placedAt: now.subtract(const Duration(seconds: 40)),
        lines: const [
          OrderLine(name: 'Poulet braisé + alloco', quantity: 2, unitPrice: 3500),
          OrderLine(name: 'Bissap 50 cl', quantity: 2, unitPrice: 500, note: 'Bien frais'),
        ],
      ),
      FoodOrder(
        id: 'o2',
        number: '#A-213',
        customerName: 'Rodrigue H.',
        placedAt: now.subtract(const Duration(minutes: 9)),
        status: OrderStatus.kitchen,
        prepMinutes: 15,
        acceptedAt: now.subtract(const Duration(minutes: 8)),
        lines: const [OrderLine(name: 'Amiwo au poulet', quantity: 1, unitPrice: 2500)],
      ),
      FoodOrder(
        id: 'o3',
        number: '#A-211',
        customerName: 'Nadège A.',
        placedAt: now.subtract(const Duration(minutes: 22)),
        status: OrderStatus.ready,
        prepMinutes: 20,
        acceptedAt: now.subtract(const Duration(minutes: 21)),
        readyAt: now.subtract(const Duration(seconds: 2)),
        lines: const [OrderLine(name: 'Pâte rouge, poisson frit', quantity: 1, unitPrice: 3000)],
      ),
    ]);
    _lastArrival = now;
  }

  final FakeBackend _fake;
  final List<FoodOrder> _orders = [];
  late DateTime _lastArrival;
  var _seq = 215;
  var _paused = false;

  static const _couriers = ['Koffi (moto)', 'Aïcha (moto)', 'Gildas (tricycle)'];
  static const _samples = [
    [OrderLine(name: 'Riz au gras, poulet', quantity: 1, unitPrice: 3000)],
    [OrderLine(name: 'Akassa + sauce feuilles', quantity: 2, unitPrice: 1500), OrderLine(name: 'Eau 1,5 L', quantity: 1, unitPrice: 600)],
    [OrderLine(name: 'Brochettes de bœuf', quantity: 3, unitPrice: 1000), OrderLine(name: 'Frites', quantity: 1, unitPrice: 1000)],
  ];
  static const _names = ['Sènan D.', 'Mariam B.', 'Ulrich T.'];

  final List<MenuItem> _menu = [
    const MenuItem(id: 'm1', name: 'Poulet braisé + alloco', category: 'Plats', price: 3500),
    const MenuItem(id: 'm2', name: 'Amiwo au poulet', category: 'Plats', price: 2500),
    const MenuItem(id: 'm3', name: 'Pâte rouge, poisson frit', category: 'Plats', price: 3000),
    const MenuItem(id: 'm4', name: 'Riz au gras, poulet', category: 'Plats', price: 3000, available: false),
    const MenuItem(id: 'm5', name: 'Brochettes de bœuf (×3)', category: 'Grillades', price: 3000),
    const MenuItem(id: 'm6', name: 'Bissap 50 cl', category: 'Boissons', price: 500),
    const MenuItem(id: 'm7', name: 'Eau 1,5 L', category: 'Boissons', price: 600),
  ];

  /// Fait avancer la démo à chaque lecture.
  void _simulate() {
    final now = DateTime.now();
    for (var i = 0; i < _orders.length; i++) {
      final o = _orders[i];
      if (o.status == OrderStatus.ready && o.readyAt != null) {
        final since = now.difference(o.readyAt!).inSeconds;
        if (since >= 8) {
          _orders[i] = o.copyWith(status: OrderStatus.pickedUp);
        } else if (since >= 2 && o.courierName == null) {
          _orders[i] = o.copyWith(courierName: _couriers[_seq % _couriers.length]);
        }
      }
    }
    final waiting = _orders.where((o) => o.status == OrderStatus.incoming).length;
    if (!_paused && waiting < 3 && now.difference(_lastArrival).inSeconds >= 20) {
      _lastArrival = now;
      final k = _seq % _samples.length;
      _orders.insert(0, FoodOrder(id: 'o$_seq', number: '#A-$_seq', customerName: _names[k], placedAt: now, lines: _samples[k]));
      _seq++;
    }
  }

  int _index(String id) {
    final i = _orders.indexWhere((o) => o.id == id);
    if (i < 0) throw const BusinessRuleException('unavailable');
    return i;
  }

  FoodOrder _update(String id, FoodOrder Function(FoodOrder o) change) {
    final i = _index(id);
    return _orders[i] = change(_orders[i]);
  }

  @override
  Future<List<FoodOrder>> orders(String establishmentId) async {
    await _fake.latency(0.3);
    _simulate();
    return List.of(_orders);
  }

  @override
  Future<FoodOrder> accept(String orderId, int prepMinutes) async {
    await _fake.latency(0.5);
    return _update(orderId, (o) => o.copyWith(status: OrderStatus.kitchen, prepMinutes: prepMinutes, acceptedAt: DateTime.now()));
  }

  @override
  Future<FoodOrder> reject(String orderId, String reason) async {
    await _fake.latency(0.5);
    return _update(orderId, (o) => o.copyWith(status: OrderStatus.rejected, rejectReason: reason));
  }

  @override
  Future<FoodOrder> extend(String orderId) async {
    await _fake.latency(0.3);
    return _update(orderId, (o) => o.copyWith(extensions: o.extensions + 1));
  }

  @override
  Future<FoodOrder> markReady(String orderId) async {
    await _fake.latency(0.4);
    return _update(orderId, (o) => o.copyWith(status: OrderStatus.ready, readyAt: DateTime.now()));
  }

  @override
  Future<RestaurantMenu> menu(String establishmentId) async {
    await _fake.latency(0.5);
    return RestaurantMenu(items: List.of(_menu), paused: _paused, hours: 'Tous les jours, 11 h – 23 h');
  }

  @override
  Future<MenuItem> setAvailability(String itemId, bool available) async {
    await _fake.latency(0.3);
    final i = _menu.indexWhere((m) => m.id == itemId);
    if (i < 0) throw const BusinessRuleException('unavailable');
    return _menu[i] = _menu[i].copyWith(available: available);
  }

  @override
  Future<bool> setPaused(String establishmentId, bool paused) async {
    await _fake.latency(0.3);
    return _paused = paused;
  }
}
