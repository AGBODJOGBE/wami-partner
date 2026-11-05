import 'package:wami_core/wami_core.dart';

import '../../../../shared/session_store.dart';
import '../../domain/entities/vehicle.dart';

abstract interface class VehiclesRemoteDataSource {
  Future<List<VehicleItem>> list();
  Future<void> add(NewVehicle v);
  Future<void> setActive(String vehicleId);
  Future<void> setCategories(String vehicleId, List<VehicleCategory> categories);
  Future<String> requestUpgrade(String vehicleId, VehicleCategory category, String? reason);
  Future<void> delete(String vehicleId);
}

List<VehicleCategory> _categories(Object? v) =>
    ((v as List<dynamic>?) ?? const []).map(VehicleCategory.fromApi).whereType<VehicleCategory>().toList();

/// `/api/vehicles/driver/*`, `/api/vehicles/:id/*` et `PATCH /api/drivers/active-vehicle`.
/// Limites du serveur : 5 véhicules au plus ; un véhicule neuf est « en vérification » jusqu'au passage d'un admin.
class VehiclesApiDataSource implements VehiclesRemoteDataSource {
  const VehiclesApiDataSource(this._api, this._session);
  final ApiClient _api;
  final SessionStore _session;

  @override
  Future<List<VehicleItem>> list() async {
    final j = await _api.get('/api/vehicles/driver/my-vehicles');
    return ((j['vehicles'] as List<dynamic>?) ?? const []).cast<Map<String, dynamic>>().map((v) {
      final active = v['isActive'] == true;
      if (active) _session.activeVehicleId = v['id'] as String?;
      return VehicleItem(
        id: '${v['id']}',
        kind: VehicleKind.fromApi(v['type']),
        make: '${v['make'] ?? ''}',
        model: '${v['model'] ?? ''}',
        year: (v['year'] as num?)?.toInt() ?? 0,
        color: '${v['color'] ?? ''}',
        plate: '${v['licensePlate'] ?? ''}',
        seats: (v['seats'] as num?)?.toInt() ?? 0,
        status: '${v['status']}',
        isVerified: v['isVerified'] == true,
        isActive: active,
        category: VehicleCategory.fromApi(v['category']),
        activeCategories: _categories(v['activeCategories']),
        selectableCategories: _categories(v['selectableCategories']),
        insuranceExpiry: DateTime.tryParse('${v['insuranceExpiryDate']}'),
      );
    }).toList();
  }

  @override
  Future<void> add(NewVehicle v) => _api.postForm('/api/vehicles/driver/add', fields: {
        'type': v.kind.api,
        'make': v.make.trim(),
        'model': v.model.trim(),
        'year': '${v.year}',
        'color': v.color.trim(),
        'licensePlate': v.plate.trim(),
        'seats': '${v.seats}',
        if (v.insuranceExpiry != null) 'insuranceExpiryDate': v.insuranceExpiry!.toUtc().toIso8601String(),
      }, files: {
        'insurance': v.insurancePath,
        if (v.registrationPath != null) 'registrationCard': v.registrationPath!,
      });

  @override
  Future<void> setActive(String vehicleId) async {
    await _api.patch('/api/drivers/active-vehicle', body: {'vehicleId': vehicleId});
    _session.activeVehicleId = vehicleId;
  }

  @override
  Future<void> setCategories(String vehicleId, List<VehicleCategory> categories) =>
      _api.patch('/api/vehicles/$vehicleId/active-categories', body: {'categories': [for (final c in categories) c.api]});

  @override
  Future<String> requestUpgrade(String vehicleId, VehicleCategory category, String? reason) async {
    final j = await _api.post('/api/vehicles/$vehicleId/upgrade-request', body: {
      'newCategory': category.api,
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    });
    return (j['message'] as String?) ?? 'Demande envoyée.';
  }

  @override
  Future<void> delete(String vehicleId) => _api.delete('/api/vehicles/$vehicleId');
}

class VehiclesFakeDataSource implements VehiclesRemoteDataSource {
  VehiclesFakeDataSource(this._fake);
  final FakeBackend _fake;

  late final _items = <VehicleItem>[
    const VehicleItem(
      id: 'v1', kind: VehicleKind.moto, make: 'Bajaj', model: 'Boxer', year: 2022, color: 'rouge', plate: 'AB 1234 RB', seats: 1,
      status: 'AVAILABLE', isVerified: true, isActive: true, activeCategories: [], selectableCategories: [],
    ),
  ];

  @override
  Future<List<VehicleItem>> list() async {
    await _fake.latency(0.4);
    return List.unmodifiable(_items);
  }

  @override
  Future<void> add(NewVehicle v) async {
    await _fake.latency(0.8);
    _items.add(VehicleItem(
      id: 'v${_items.length + 1}', kind: v.kind, make: v.make, model: v.model, year: v.year, color: v.color, plate: v.plate,
      seats: v.seats, status: 'PENDING', isVerified: false, isActive: false, activeCategories: const [], selectableCategories: const [],
    ));
  }

  @override
  Future<void> setActive(String vehicleId) async {
    await _fake.latency(0.3);
    for (var i = 0; i < _items.length; i++) {
      final v = _items[i];
      _items[i] = VehicleItem(
        id: v.id, kind: v.kind, make: v.make, model: v.model, year: v.year, color: v.color, plate: v.plate, seats: v.seats,
        status: v.status, isVerified: v.isVerified, isActive: v.id == vehicleId, category: v.category,
        activeCategories: v.activeCategories, selectableCategories: v.selectableCategories,
      );
    }
  }

  @override
  Future<void> setCategories(String vehicleId, List<VehicleCategory> categories) => _fake.latency(0.3);

  @override
  Future<String> requestUpgrade(String vehicleId, VehicleCategory category, String? reason) async {
    await _fake.latency(0.4);
    return 'Demande reçue.';
  }

  @override
  Future<void> delete(String vehicleId) async {
    await _fake.latency(0.3);
    _items.removeWhere((v) => v.id == vehicleId);
  }
}
