import 'package:wami_core/wami_core.dart';

import '../../../../shared/business_activity.dart';
import '../../domain/entities/business.dart';

abstract interface class OnboardingRemoteDataSource {
  Future<BusinessSession?> currentSession();
  Future<void> requestCode(String phone);
  Future<BusinessSession> verifyCode(String phone, String code);
  Future<BusinessSession> register(Set<BusinessActivity> activities, String name, String district);
  Future<VerificationChecklist> checklist();
  Future<VerificationChecklist> sendItem(String id);
  Future<void> logout();
}

BusinessSession _session(Map<String, dynamic> j) => BusinessSession(
      phone: j['phone'] as String,
      status: BusinessStatus.values.byName(j['status'] as String),
      businessName: j['business_name'] as String?,
    );

VerificationChecklist _checklist(Map<String, dynamic> j) => VerificationChecklist([
      for (final i in (j['items'] as List<dynamic>).cast<Map<String, dynamic>>())
        ChecklistItem(
          id: i['id'] as String,
          label: i['label'] as String,
          hint: i['hint'] as String? ?? '',
          state: ChecklistState.values.byName(i['state'] as String),
          rejectReason: i['reject_reason'] as String?,
        ),
    ]);

/// Endpoints à valider avec l'équipe back-end.
class OnboardingApiDataSource implements OnboardingRemoteDataSource {
  const OnboardingApiDataSource(this._api, this._auth);
  final ApiClient _api;
  final AuthInterceptor _auth;

  @override
  Future<BusinessSession?> currentSession() async {
    final j = await _api.get('/v1/business/me');
    return j.isEmpty ? null : _session(j);
  }

  @override
  Future<void> requestCode(String phone) => _api.post('/v1/auth/otp', body: {'phone': phone, 'app': 'business'});

  @override
  Future<BusinessSession> verifyCode(String phone, String code) async {
    final j = await _api.post('/v1/auth/otp/verify', body: {'phone': phone, 'code': code});
    // À valider : stocker le jeton (flutter_secure_storage).
    _auth.updateToken(j['access_token'] as String?);
    return _session(j['business'] as Map<String, dynamic>);
  }

  @override
  Future<BusinessSession> register(Set<BusinessActivity> activities, String name, String district) async {
    return _session(await _api.post('/v1/business', body: {
      'activities': [for (final a in activities) a.name],
      'name': name,
      'district': district,
    }));
  }

  @override
  Future<VerificationChecklist> checklist() async => _checklist(await _api.get('/v1/business/me/verification'));

  @override
  Future<VerificationChecklist> sendItem(String id) async =>
      _checklist(await _api.post('/v1/business/me/verification/$id'));

  @override
  Future<void> logout() async => _auth.updateToken(null);
}

/// Démo : code SMS 1234 ; chaque pièce envoyée est validée 3 s plus tard.
class OnboardingFakeDataSource implements OnboardingRemoteDataSource {
  OnboardingFakeDataSource(this._fake);
  final FakeBackend _fake;

  static const demoCode = '1234';

  BusinessSession? _current;
  String _phone = '';
  final Map<String, DateTime> _sentAt = {};
  final List<ChecklistItem> _items = const [
    ChecklistItem(id: 'id', label: 'Pièce d’identité du gérant', hint: 'CNI, passeport ou CIP'),
    ChecklistItem(id: 'company', label: 'RCCM ou IFU', hint: 'À valider : pièce exigée selon l’activité'),
    ChecklistItem(id: 'photos', label: 'Photos de l’établissement', hint: 'Façade, salle ou chambres'),
    ChecklistItem(id: 'payout', label: 'Compte Mobile Money', hint: 'Pour recevoir vos versements'),
    ChecklistItem(id: 'charter', label: 'Charte partenaire', hint: 'Lire et accepter'),
  ];

  @override
  Future<BusinessSession?> currentSession() async {
    await _fake.latency(0.4);
    return _current;
  }

  @override
  Future<void> requestCode(String phone) async {
    await _fake.latency();
    _phone = phone;
  }

  @override
  Future<BusinessSession> verifyCode(String phone, String code) async {
    await _fake.latency();
    if (code != demoCode) throw const BusinessRuleException('bad_code', 'Code incorrect. En démo : 1234.');
    return _current = BusinessSession(phone: _phone, status: BusinessStatus.newcomer);
  }

  @override
  Future<BusinessSession> register(Set<BusinessActivity> activities, String name, String district) async {
    await _fake.latency();
    return _current = BusinessSession(phone: _phone, status: BusinessStatus.verifying, businessName: name);
  }

  VerificationChecklist _snapshot() {
    final now = DateTime.now();
    return VerificationChecklist([
      for (final i in _items)
        switch (_sentAt[i.id]) {
          null => i,
          final DateTime t when now.difference(t).inSeconds >= 3 => i.copyWith(state: ChecklistState.approved),
          _ => i.copyWith(state: ChecklistState.sent),
        },
    ]);
  }

  @override
  Future<VerificationChecklist> checklist() async {
    await _fake.latency(0.4);
    final c = _snapshot();
    if (c.isComplete && _current != null) {
      _current = BusinessSession(phone: _current!.phone, status: BusinessStatus.active, businessName: _current!.businessName);
    }
    return c;
  }

  @override
  Future<VerificationChecklist> sendItem(String id) async {
    await _fake.latency(0.8);
    _sentAt[id] = DateTime.now();
    return _snapshot();
  }

  @override
  Future<void> logout() async {
    await _fake.latency(0.3);
    _current = null;
    _sentAt.clear();
  }
}
