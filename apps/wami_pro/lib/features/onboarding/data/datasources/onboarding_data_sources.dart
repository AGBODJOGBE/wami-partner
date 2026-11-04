import 'package:wami_core/wami_core.dart';

import '../../domain/entities/partner.dart';

abstract interface class OnboardingRemoteDataSource {
  Future<PartnerSession?> currentSession();
  Future<void> requestCode(String phone);
  Future<PartnerSession> verifyCode(String phone, String code);
  Future<void> register(Set<PartnerActivity> activities, VehicleType vehicle);
  Future<List<PartnerDocument>> documents();
  Future<PartnerDocument> upload(DocumentType type);
  Future<void> submit();
  Future<VerificationProgress> verification();
  Future<void> completeTraining();
  Future<void> logout();
}

PartnerSession _session(Map<String, dynamic> j) => PartnerSession(
      phone: j['phone'] as String,
      status: PartnerStatus.values.byName(j['status'] as String),
    );

PartnerDocument _doc(Map<String, dynamic> j) => PartnerDocument(
      type: DocumentType.values.byName(j['type'] as String),
      status: DocumentStatus.values.byName(j['status'] as String),
      rejectionReason: j['rejection_reason'] as String?,
    );

/// Endpoints à valider avec l'équipe back. Le jeton reçu à la vérification du
/// code doit être stocké (flutter_secure_storage) et passé à AuthInterceptor.
class OnboardingApiDataSource implements OnboardingRemoteDataSource {
  const OnboardingApiDataSource(this._api, this._auth);
  final ApiClient _api;
  final AuthInterceptor _auth;

  @override
  Future<PartnerSession?> currentSession() async {
    final j = await _api.get('/v1/partners/me');
    return j.isEmpty ? null : _session(j);
  }

  @override
  Future<void> requestCode(String phone) => _api.post('/v1/auth/otp', body: {'phone': phone, 'app': 'pro'});

  @override
  Future<PartnerSession> verifyCode(String phone, String code) async {
    final j = await _api.post('/v1/auth/otp/verify', body: {'phone': phone, 'code': code});
    _auth.updateToken(j['access_token'] as String?);
    return _session(j['partner'] as Map<String, dynamic>);
  }

  @override
  Future<void> register(Set<PartnerActivity> activities, VehicleType vehicle) => _api.post('/v1/partners', body: {
        'activities': activities.map((a) => a.name).toList(),
        'vehicle': vehicle.name,
      });

  @override
  Future<List<PartnerDocument>> documents() async =>
      ((await _api.get('/v1/partners/me/documents'))['items'] as List<dynamic>).cast<Map<String, dynamic>>().map(_doc).toList();

  @override
  Future<PartnerDocument> upload(DocumentType type) async =>
      _doc(await _api.post('/v1/partners/me/documents', body: {'type': type.name}));

  @override
  Future<void> submit() => _api.post('/v1/partners/me/review');

  @override
  Future<VerificationProgress> verification() async {
    final j = await _api.get('/v1/partners/me/verification');
    return VerificationProgress(
      documentsSent: j['documents_sent'] as bool,
      reviewDone: j['review_done'] as bool,
      trainingDone: j['training_done'] as bool,
      vehicleChecked: j['vehicle_checked'] as bool,
      reviewDelay: j['review_delay'] as String? ?? '',
    );
  }

  @override
  Future<void> completeTraining() => _api.post('/v1/partners/me/training');

  @override
  Future<void> logout() async => _auth.updateToken(null);
}

/// Inscription simulée. Code SMS de démonstration : 1234.
/// Après la soumission, la vérification et le contrôle du véhicule se valident
/// automatiquement au bout de quelques secondes.
class OnboardingFakeDataSource implements OnboardingRemoteDataSource {
  OnboardingFakeDataSource(this._fake);
  final FakeBackend _fake;

  static const demoCode = '1234';

  PartnerSession? _session;
  DateTime? _submittedAt;
  bool _training = false;
  final _docs = <DocumentType, DocumentStatus>{
    DocumentType.identity: DocumentStatus.approved,
    DocumentType.photo: DocumentStatus.approved,
    DocumentType.license: DocumentStatus.pending,
  };

  @override
  Future<PartnerSession?> currentSession() async {
    await _fake.latency(0.3);
    return _session;
  }

  @override
  Future<void> requestCode(String phone) => _fake.latency();

  @override
  Future<PartnerSession> verifyCode(String phone, String code) async {
    await _fake.latency();
    if (code != demoCode) throw const BusinessRuleException('bad_code', 'Code incorrect. Démo : 1234.');
    return _session = PartnerSession(phone: phone, status: PartnerStatus.newcomer);
  }

  @override
  Future<void> register(Set<PartnerActivity> activities, VehicleType vehicle) => _fake.latency();

  @override
  Future<List<PartnerDocument>> documents() async {
    await _fake.latency(0.5);
    return [
      for (final t in DocumentType.values) PartnerDocument(type: t, status: _docs[t] ?? DocumentStatus.missing),
    ];
  }

  @override
  Future<PartnerDocument> upload(DocumentType type) async {
    await _fake.latency(1.2);
    _docs[type] = DocumentStatus.pending;
    return PartnerDocument(type: type, status: DocumentStatus.pending);
  }

  @override
  Future<void> submit() async {
    await _fake.latency();
    _submittedAt = DateTime.now();
    _session = PartnerSession(phone: _session?.phone ?? '', status: PartnerStatus.underReview);
  }

  @override
  Future<VerificationProgress> verification() async {
    await _fake.latency(0.3);
    final since = _submittedAt == null ? Duration.zero : DateTime.now().difference(_submittedAt!);
    final reviewed = since.inSeconds >= 4;
    final checked = since.inSeconds >= 6;
    final progress = VerificationProgress(
      documentsSent: _submittedAt != null,
      reviewDone: reviewed,
      trainingDone: _training,
      vehicleChecked: checked,
    );
    if (progress.isActive) {
      _session = PartnerSession(phone: _session?.phone ?? '', status: PartnerStatus.active);
    }
    return progress;
  }

  @override
  Future<void> completeTraining() async {
    await _fake.latency();
    _training = true;
  }

  @override
  Future<void> logout() async {
    _session = null;
  }
}
