import 'package:wami_core/wami_core.dart';

import '../../../../shared/session_store.dart';
import '../../domain/entities/driver_profile.dart';

abstract interface class ProfileRemoteDataSource {
  Future<DriverProfile> profile();
  Future<String> change(ProfileChange change);
  Future<void> deleteAccount(String password);
}

String _e164(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  return raw.trim().startsWith('+') ? '+$digits' : '+229$digits';
}

/// `GET /api/drivers/profile`, `/api/users/:userId/*` (le `:id` est le **userId**, pas le driverId)
/// et `DELETE /api/drivers/profile` (mot de passe requis, jeton révoqué, sans garde sur une course en cours).
class ProfileApiDataSource implements ProfileRemoteDataSource {
  const ProfileApiDataSource(this._api, this._session);
  final ApiClient _api;
  final SessionStore _session;

  String get _user => '/api/users/${_session.requireIdentity.userId}';

  @override
  Future<DriverProfile> profile() async {
    final p = await _api.get('/api/drivers/profile');
    final a = p['address'] is Map ? p['address'] as Map : const {};
    final email = p['email'] as String?;
    return DriverProfile(
      firstName: '${p['firstName'] ?? ''}',
      lastName: '${p['lastName'] ?? ''}',
      phone: '${p['phoneNumber'] ?? ''}',
      phoneVerified: p['isPhoneVerified'] == true,
      email: (email == null || email.isEmpty) ? null : email,
      emailVerified: p['isEmailVerified'] == true,
      city: '${a['city'] ?? ''}',
      quarter: '${a['quarter'] ?? ''}',
    );
  }

  @override
  Future<String> change(ProfileChange c) async {
    final Map<String, dynamic> j = switch (c) {
      ChangeName(:final firstName, :final lastName) =>
        await _api.patch('$_user/name', body: {'firstName': firstName.trim(), 'lastName': lastName.trim()}),
      ChangeAddress(:final city, :final quarter) =>
        await _api.patch('$_user/address', body: {'address': {'city': city.trim(), 'quarter': quarter.trim()}}),
      ChangeEmail(:final email, :final hadEmail) => hadEmail
          ? await _api.patch('$_user/email', body: {'newEmail': email.trim()})
          : await _api.post('$_user/add-email', body: {'email': email.trim()}),
      VerifyEmail(:final code) => await _api.post('$_user/verify-email', body: {'code': code.trim()}),
      ChangePhone(:final phone) => await _api.patch('$_user/phone', body: {'newPhoneNumber': _e164(phone)}),
      VerifyPhone(:final code) => await _api.post('$_user/verify-phone', body: {'code': code.trim()}),
    };
    return (j['message'] as String?) ?? 'Modifié.';
  }

  @override
  Future<void> deleteAccount(String password) async {
    await _api.delete('/api/drivers/profile', body: {'password': password});
    await _session.clear();
  }
}

class ProfileFakeDataSource implements ProfileRemoteDataSource {
  ProfileFakeDataSource(this._fake);
  final FakeBackend _fake;

  DriverProfile _p = const DriverProfile(
    firstName: 'Prénom', lastName: 'Nom', phone: '+2290197000000', phoneVerified: true, email: null, emailVerified: false, city: 'Cotonou', quarter: 'Cadjèhoun',
  );

  @override
  Future<DriverProfile> profile() async {
    await _fake.latency(0.4);
    return _p;
  }

  @override
  Future<String> change(ProfileChange c) async {
    await _fake.latency(0.4);
    switch (c) {
      case ChangeName(:final firstName, :final lastName):
        _p = DriverProfile(firstName: firstName, lastName: lastName, phone: _p.phone, phoneVerified: _p.phoneVerified, email: _p.email, emailVerified: _p.emailVerified, city: _p.city, quarter: _p.quarter);
      case ChangeAddress(:final city, :final quarter):
        _p = DriverProfile(firstName: _p.firstName, lastName: _p.lastName, phone: _p.phone, phoneVerified: _p.phoneVerified, email: _p.email, emailVerified: _p.emailVerified, city: city, quarter: quarter);
      case ChangeEmail(:final email):
        _p = DriverProfile(firstName: _p.firstName, lastName: _p.lastName, phone: _p.phone, phoneVerified: _p.phoneVerified, email: email, emailVerified: false, city: _p.city, quarter: _p.quarter);
      case VerifyEmail():
        _p = DriverProfile(firstName: _p.firstName, lastName: _p.lastName, phone: _p.phone, phoneVerified: _p.phoneVerified, email: _p.email, emailVerified: true, city: _p.city, quarter: _p.quarter);
      case ChangePhone() || VerifyPhone():
        break;
    }
    return 'Enregistré.';
  }

  @override
  Future<void> deleteAccount(String password) => _fake.latency(0.5);
}
