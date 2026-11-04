import 'package:wami_core/wami_core.dart';

import '../../../../shared/session_store.dart';
import '../../domain/entities/partner.dart';

abstract interface class OnboardingRemoteDataSource {
  Future<PartnerSession?> currentSession();
  Future<void> requestCode(String phone);
  Future<void> verifyCode(String phone, String code);
  Future<PartnerSession> register(RegistrationForm form);
  Future<PartnerSession> login(String phone, String password);
  Future<void> forgotPassword(String phone);
  Future<void> resetPassword(String phone, String code, String newPassword);
  Future<List<PartnerDocument>> documents();
  Future<PartnerDocument> upload(DocumentType type, String filePath);
  Future<void> submit();
  Future<VerificationProgress> verification();
  Future<void> completeTraining();
  Future<void> logout();
}

/// Le serveur attend le numéro au format international : +229 puis les chiffres.
String _e164(String digits) => digits.startsWith('+') ? digits : '+229$digits';

String _digits(String e164) => e164.replaceFirst('+229', '');

/// Statut de document renvoyé par le serveur → statut de l'app.
DocumentStatus _docStatus(String s) => switch (s) {
      'VERIFIED' => DocumentStatus.approved,
      'REJECTED' || 'EXPIRED' => DocumentStatus.rejected,
      _ => DocumentStatus.pending,
    };

/// Routes du serveur WAMI (`/api/drivers`, `/api/documents`, `/api/vehicles`).
///
/// Ce que le serveur ne fait pas, et ce que l'app fait à sa place :
/// - pas de « dossier envoyé » explicite : `submit` ne fait rien, la vérification est lue
///   dans le statut des documents et du véhicule ;
/// - pas de formation en ligne : l'étape est considérée comme faite.
class OnboardingApiDataSource implements OnboardingRemoteDataSource {
  OnboardingApiDataSource(this._api, this._session);
  final ApiClient _api;
  final SessionStore _session;

  String? _vehicleId;
  List<Map<String, dynamic>> _docs = const [];

  @override
  Future<PartnerSession?> currentSession() async {
    final id = await _session.restore();
    if (id == null) return null;
    try {
      await _api.get('/api/drivers/me/verify-token');
    } on NetworkException {
      // Hors connexion : on garde la session, le serveur tranchera à la première action.
      return PartnerSession(phone: _digits(id.phone), status: PartnerStatus.active);
    } on BusinessRuleException {
      await _session.clear();
      return null;
    }
    return _sessionFor(id);
  }

  @override
  Future<void> requestCode(String phone) => _api.post('/api/drivers/send-otp', body: {'phoneNumber': _e164(phone)});

  @override
  Future<void> verifyCode(String phone, String code) =>
      _api.post('/api/drivers/verify-otp', body: {'phoneNumber': _e164(phone), 'code': code});

  @override
  Future<PartnerSession> register(RegistrationForm f) async {
    final j = await _api.postForm('/api/drivers/register', fields: {
      'phoneNumber': _e164(f.phone),
      'password': f.password,
      'firstName': f.firstName.trim(),
      'lastName': f.lastName.trim(),
      'gender': f.gender.apiName,
      'category': 'STANDARD',
      'driverType': PartnerActivity.apiType(f.activities),
      'isVehicleOwner': 'true',
      'ownVehicle[type]': f.vehicle.apiName,
      'ownVehicle[make]': f.make.trim(),
      'ownVehicle[model]': f.model.trim(),
      'ownVehicle[year]': '${f.year}',
      'ownVehicle[color]': f.color.trim(),
      'ownVehicle[licensePlate]': f.plate.trim(),
      'ownVehicle[seats]': '${f.seats}',
    });
    _vehicleId = j['vehicleId'] as String?;
    return login(f.phone, f.password);
  }

  @override
  Future<PartnerSession> login(String phone, String password) async {
    final j = await _api.post('/api/drivers/login', body: {'phoneNumber': _e164(phone), 'password': password});
    final u = (j['user'] as Map<String, dynamic>?) ?? const {};
    final id = DriverIdentity(
      token: j['token'] as String,
      userId: u['userId'] as String? ?? '',
      driverId: u['driverId'] as String? ?? '',
      walletId: u['walletId'] as String? ?? '',
      phone: _e164(phone),
      firstName: u['firstName'] as String? ?? '',
      lastName: u['lastName'] as String? ?? '',
      driverType: u['driverType'] as String? ?? 'VTC',
    );
    await _session.save(id);
    return _sessionFor(id, suspended: u['status'] == 'SUSPENDED');
  }

  @override
  Future<void> forgotPassword(String phone) => _api.post('/api/drivers/password/forgot', body: {'phoneNumber': _e164(phone)});

  @override
  Future<void> resetPassword(String phone, String code, String newPassword) => _api.post(
        '/api/drivers/password/reset',
        body: {'phoneNumber': _e164(phone), 'verificationCode': code, 'newPassword': newPassword},
      );

  // ── Documents ──

  Future<String?> _ensureVehicleId() async {
    if (_vehicleId != null) return _vehicleId;
    try {
      final v = await _api.get('/api/drivers/vehicle');
      return _vehicleId = v['id'] as String?;
    } on BusinessRuleException {
      return null; // aucun véhicule assigné
    }
  }

  /// Documents du chauffeur puis du véhicule, à plat.
  Future<List<Map<String, dynamic>>> _loadDocs() async {
    final list = <Map<String, dynamic>>[];
    Future<void> add(Map<String, String> query) async {
      final j = await _api.get('/api/documents/my-documents', query: query);
      list.addAll(((j['documents'] as List<dynamic>?) ?? const []).cast<Map<String, dynamic>>());
    }

    await add({'ownerType': 'DRIVER'});
    final vehicleId = await _ensureVehicleId();
    if (vehicleId != null) await add({'ownerType': 'VEHICLE', 'vehicleId': vehicleId});
    return _docs = list;
  }

  /// Dernier document d'un type (le plus récent).
  Map<String, dynamic>? _latest(DocumentType t) {
    final same = _docs.where((d) => d['type'] == t.apiName).toList()
      ..sort((a, b) => '${b['createdAt']}'.compareTo('${a['createdAt']}'));
    return same.firstOrNull;
  }

  PartnerDocument _toDoc(DocumentType t, Map<String, dynamic>? d) {
    if (d == null) return PartnerDocument(type: t, status: DocumentStatus.missing);
    final status = _docStatus(d['status'] as String? ?? 'PENDING');
    return PartnerDocument(
      type: t,
      status: status,
      rejectionReason: d['status'] == 'EXPIRED' ? 'Document expiré' : (status == DocumentStatus.rejected ? 'Refusé : renvoyez une photo nette' : null),
    );
  }

  @override
  Future<List<PartnerDocument>> documents() async {
    await _loadDocs();
    return [for (final t in DocumentType.values) _toDoc(t, _latest(t))];
  }

  @override
  Future<PartnerDocument> upload(DocumentType type, String filePath) async {
    await _loadDocs();
    final existing = _latest(type);
    // Le serveur refuse un doublon : on remplace un document en attente ou refusé.
    if (existing != null && existing['status'] != 'VERIFIED') {
      await _api.delete('/api/documents/${existing['documentId']}');
    }
    final fields = <String, String>{'documentType': type.apiName, 'ownerType': type.belongsToVehicle ? 'VEHICLE' : 'DRIVER'};
    if (type.belongsToVehicle) {
      final vehicleId = await _ensureVehicleId();
      if (vehicleId == null) throw const BusinessRuleException('no_vehicle', 'Aucun véhicule enregistré pour ce document.');
      fields['vehicleId'] = vehicleId;
    }
    final j = await _api.postForm('/api/documents/upload', fields: fields, files: {'file': filePath});
    return _toDoc(type, j);
  }

  @override
  Future<void> submit() async {} // pas d'étape « soumettre » côté serveur

  Future<PartnerSession> _sessionFor(DriverIdentity id, {bool suspended = false}) async {
    final p = await verification();
    final status = suspended
        ? PartnerStatus.suspended
        : p.isActive
            ? PartnerStatus.active
            : (p.documentsSent ? PartnerStatus.underReview : PartnerStatus.newcomer);
    return PartnerSession(phone: _digits(id.phone), status: status);
  }

  @override
  Future<VerificationProgress> verification() async {
    final docs = await documents();
    var vehicleChecked = false;
    try {
      final v = await _api.get('/api/drivers/vehicle');
      vehicleChecked = v['isVerified'] == true && !{'PENDING', 'REJECTED', 'RETIRED', 'MAINTENANCE'}.contains(v['status']);
    } on BusinessRuleException {
      vehicleChecked = false;
    }
    return VerificationProgress(
      documentsSent: docs.every((d) => d.status.isSent),
      reviewDone: docs.every((d) => d.status == DocumentStatus.approved),
      trainingDone: true,
      vehicleChecked: vehicleChecked,
    );
  }

  @override
  Future<void> completeTraining() async {}

  @override
  Future<void> logout() => _session.clear();
}

/// Inscription simulée. Code SMS de démonstration : 123456, mot de passe libre.
/// Après l'envoi des pièces, la vérification et le contrôle du véhicule se valident
/// automatiquement au bout de quelques secondes.
class OnboardingFakeDataSource implements OnboardingRemoteDataSource {
  OnboardingFakeDataSource(this._fake);
  final FakeBackend _fake;

  static const demoCode = '123456';

  PartnerSession? _session;
  DateTime? _submittedAt;
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
  Future<void> verifyCode(String phone, String code) async {
    await _fake.latency();
    if (code != demoCode) throw const BusinessRuleException('bad_code', 'Code incorrect. Démo : 123456.');
  }

  @override
  Future<PartnerSession> register(RegistrationForm form) async {
    await _fake.latency();
    return _session = PartnerSession(phone: form.phone, status: PartnerStatus.newcomer);
  }

  @override
  Future<PartnerSession> login(String phone, String password) async {
    await _fake.latency();
    return _session = PartnerSession(phone: phone, status: PartnerStatus.active);
  }

  @override
  Future<void> forgotPassword(String phone) => _fake.latency();

  @override
  Future<void> resetPassword(String phone, String code, String newPassword) async {
    await _fake.latency();
    if (code != demoCode) throw const BusinessRuleException('bad_code', 'Code incorrect. Démo : 123456.');
  }

  @override
  Future<List<PartnerDocument>> documents() async {
    await _fake.latency(0.5);
    return [
      for (final t in DocumentType.values) PartnerDocument(type: t, status: _docs[t] ?? DocumentStatus.missing),
    ];
  }

  @override
  Future<PartnerDocument> upload(DocumentType type, String filePath) async {
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
    final progress = VerificationProgress(
      documentsSent: _submittedAt != null,
      reviewDone: since.inSeconds >= 4,
      trainingDone: true,
      vehicleChecked: since.inSeconds >= 6,
    );
    if (progress.isActive) {
      _session = PartnerSession(phone: _session?.phone ?? '', status: PartnerStatus.active);
    }
    return progress;
  }

  @override
  Future<void> completeTraining() async {}

  @override
  Future<void> logout() async {
    _session = null;
  }
}
