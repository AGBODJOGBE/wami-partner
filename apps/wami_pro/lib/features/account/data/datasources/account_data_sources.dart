import 'package:wami_core/wami_core.dart';

import '../../../../shared/session_store.dart';
import '../../domain/entities/partner_account.dart';

abstract interface class AccountRemoteDataSource {
  Future<PartnerAccount> account();
  Future<PartnerPreferences> savePreferences(PartnerPreferences p);
  Future<void> changePassword(String current, String next);
}

const _months = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];

String _since(Object? iso) {
  final d = DateTime.tryParse('$iso')?.toLocal();
  return d == null ? '—' : '${_months[d.month - 1]} ${d.year}';
}

String _role(String driverType, Object? vehicleType) {
  final v = switch (vehicleType) {
    'MOTO' => 'moto',
    'TRICYCLE' => 'tricycle',
    'CAR' => 'voiture',
    _ => '',
  };
  final base = driverType == 'DELIVERY' ? 'Livreur' : (driverType == 'BOTH' ? 'Chauffeur et livreur' : 'Chauffeur');
  return v.isEmpty ? base : '$base $v';
}

String _docLabel(Object? type) => switch (type) {
      'IDENTITY_CARD' => 'Pièce d’identité',
      'PROFILE_PHOTO' => 'Photo de profil',
      'DRIVERS_LICENSE' => 'Permis de conduire',
      'REGISTRATION_CARD' => 'Carte grise',
      'INSURANCE' => 'Assurance',
      'CRIMINAL_RECORD' => 'Casier judiciaire',
      _ => '$type',
    };

/// Compte via `/api/drivers/profile`, `/api/drivers/vehicle` et `/api/documents/my-documents`.
///
/// Écarts avec le serveur :
/// - le serveur n'a pas de préférences de missions : elles sont gardées sur l'appareil seulement
///   (en mémoire) et n'influencent pas encore la répartition ;
/// - il n'expose ni « approuvé » ni dates de validité propres : la conformité vient du statut des
///   documents (vérifié, en attente, refusé, expiré) et de leur date d'expiration.
class AccountApiDataSource implements AccountRemoteDataSource {
  AccountApiDataSource(this._api, this._session);
  final ApiClient _api;
  final SessionStore _session;

  PartnerPreferences _p = const PartnerPreferences();

  @override
  Future<PartnerAccount> account() async {
    final p = await _api.get('/api/drivers/profile');
    Map<String, dynamic>? v;
    try {
      v = await _api.get('/api/drivers/vehicle');
    } on BusinessRuleException {
      v = null; // pas encore de véhicule assigné
    }
    final docs = <Map<String, dynamic>>[];
    Future<void> add(Map<String, String> q) async {
      final j = await _api.get('/api/documents/my-documents', query: q);
      docs.addAll(((j['documents'] as List<dynamic>?) ?? const []).cast<Map<String, dynamic>>());
    }

    await add({'ownerType': 'DRIVER'});
    final vehicleId = v?['id'] as String?;
    if (vehicleId != null) await add({'ownerType': 'VEHICLE', 'vehicleId': vehicleId});

    final now = DateTime.now();
    return PartnerAccount(
      name: '${p['firstName'] ?? _session.identity?.firstName ?? ''} ${p['lastName'] ?? _session.identity?.lastName ?? ''}'.trim(),
      role: _role(_session.identity?.driverType ?? 'VTC', v?['type']),
      memberSince: _since(p['createdAt']),
      vehicle: v == null ? 'Aucun véhicule' : '${v['make'] ?? ''} ${v['model'] ?? ''} · ${v['color'] ?? ''}'.trim(),
      plate: (v?['licensePlate'] as String?) ?? '',
      compliance: [
        for (final d in docs)
          () {
            final expires = DateTime.tryParse('${d['expiresAt']}')?.toLocal();
            final days = expires?.difference(now).inDays;
            final status = d['status'];
            final state = (status == 'EXPIRED' || status == 'REJECTED' || (days != null && days < 0))
                ? ComplianceState.expired
                : ((days != null && days <= 30) ? ComplianceState.expiringSoon : ComplianceState.ok);
            return ComplianceItem(
              label: '${_docLabel(d['type'])}${status == 'PENDING' ? ' (en vérification)' : ''}',
              state: state,
              daysLeft: state == ComplianceState.expiringSoon ? days : null,
            );
          }(),
      ],
      preferences: _p,
    );
  }

  @override
  Future<PartnerPreferences> savePreferences(PartnerPreferences p) async => _p = p;

  @override
  Future<void> changePassword(String current, String next) =>
      _api.put('/api/drivers/password', body: {'currentPassword': current, 'newPassword': next});
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

  @override
  Future<void> changePassword(String current, String next) => _fake.latency(0.5);
}
