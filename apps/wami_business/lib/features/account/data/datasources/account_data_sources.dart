import 'package:wami_core/wami_core.dart';

import '../../domain/entities/business_account.dart';

abstract interface class AccountRemoteDataSource {
  Future<BusinessAccount> account();
  Future<TeamMember> invite(String name, String phone, TeamRole role);
  Future<void> remove(String memberId);
}

TeamMember _member(Map<String, dynamic> j) => TeamMember(
      id: j['id'] as String,
      name: j['name'] as String,
      phone: j['phone'] as String,
      role: TeamRole.values.byName(j['role'] as String),
      pending: j['pending'] as bool? ?? false,
    );

/// Endpoints à valider.
class AccountApiDataSource implements AccountRemoteDataSource {
  const AccountApiDataSource(this._api);
  final ApiClient _api;

  @override
  Future<BusinessAccount> account() async {
    final j = await _api.get('/v1/business/me/account');
    return BusinessAccount(
      businessName: j['business_name'] as String,
      ownerName: j['owner_name'] as String,
      phone: j['phone'] as String,
      memberSince: j['member_since'] as String,
      team: [for (final m in (j['team'] as List<dynamic>).cast<Map<String, dynamic>>()) _member(m)],
    );
  }

  @override
  Future<TeamMember> invite(String name, String phone, TeamRole role) async =>
      _member(await _api.post('/v1/business/me/team', body: {'name': name, 'phone': phone, 'role': role.name}));

  @override
  Future<void> remove(String memberId) => _api.post('/v1/business/me/team/$memberId/remove');
}

class AccountFakeDataSource implements AccountRemoteDataSource {
  AccountFakeDataSource(this._fake);
  final FakeBackend _fake;
  var _seq = 3;

  final List<TeamMember> _team = [
    const TeamMember(id: 't1', name: '[Nom du gérant]', phone: '0197000000', role: TeamRole.owner),
    const TeamMember(id: 't2', name: 'Bernadette H.', phone: '0196112233', role: TeamRole.manager),
  ];

  @override
  Future<BusinessAccount> account() async {
    await _fake.latency(0.5);
    return BusinessAccount(
      businessName: '[Nom de l’entreprise]',
      ownerName: '[Nom du gérant]',
      phone: '+229 01 97 00 00 00',
      memberSince: 'novembre 2026',
      team: List.of(_team),
    );
  }

  @override
  Future<TeamMember> invite(String name, String phone, TeamRole role) async {
    await _fake.latency(0.6);
    final m = TeamMember(id: 't${_seq++}', name: name, phone: phone, role: role, pending: true);
    _team.add(m);
    return m;
  }

  @override
  Future<void> remove(String memberId) async {
    await _fake.latency(0.4);
    _team.removeWhere((m) => m.id == memberId);
  }
}
