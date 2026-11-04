import 'package:wami_core/wami_core.dart';

import '../../domain/entities/partner_account.dart';

abstract interface class AccountRemoteDataSource {
  Future<PartnerAccount> account();
  Future<PartnerPreferences> savePreferences(PartnerPreferences p);
}

PartnerPreferences _prefs(Map<String, dynamic> j) => PartnerPreferences(
      acceptDeliveries: j['accept_deliveries'] as bool? ?? true,
      acceptCash: j['accept_cash'] as bool? ?? true,
      longTrips: j['long_trips'] as bool? ?? false,
    );

Map<String, dynamic> _prefsJson(PartnerPreferences p) =>
    {'accept_deliveries': p.acceptDeliveries, 'accept_cash': p.acceptCash, 'long_trips': p.longTrips};

/// Endpoints à valider.
class AccountApiDataSource implements AccountRemoteDataSource {
  const AccountApiDataSource(this._api);
  final ApiClient _api;

  @override
  Future<PartnerAccount> account() async {
    final j = await _api.get('/v1/partners/me/account');
    return PartnerAccount(
      name: j['name'] as String,
      role: j['role'] as String,
      memberSince: j['member_since'] as String,
      vehicle: j['vehicle'] as String,
      plate: j['plate'] as String,
      compliance: (j['compliance'] as List<dynamic>).cast<Map<String, dynamic>>().map((c) {
        return ComplianceItem(
          label: c['label'] as String,
          state: ComplianceState.values.byName(c['state'] as String),
          daysLeft: c['days_left'] as int?,
        );
      }).toList(),
      preferences: _prefs(j['preferences'] as Map<String, dynamic>),
    );
  }

  @override
  Future<PartnerPreferences> savePreferences(PartnerPreferences p) async =>
      _prefs(await _api.put('/v1/partners/me/preferences', body: _prefsJson(p)));
}

class AccountFakeDataSource implements AccountRemoteDataSource {
  AccountFakeDataSource(this._fake);
  final FakeBackend _fake;

  PartnerPreferences _p = const PartnerPreferences();

  @override
  Future<PartnerAccount> account() async {
    await _fake.latency(0.5);
    return PartnerAccount(
      name: '[Nom du partenaire]',
      role: 'Chauffeur moto',
      memberSince: 'mars 2026',
      vehicle: 'Bajaj Boxer · rouge',
      plate: '[PLAQUE]',
      compliance: const [
        ComplianceItem(label: 'Permis, identité, carte grise', state: ComplianceState.ok),
        ComplianceItem(label: 'Assurance', state: ComplianceState.expiringSoon, daysLeft: 12),
      ],
      preferences: _p,
    );
  }

  @override
  Future<PartnerPreferences> savePreferences(PartnerPreferences p) async {
    await _fake.latency(0.3);
    return _p = p;
  }
}
