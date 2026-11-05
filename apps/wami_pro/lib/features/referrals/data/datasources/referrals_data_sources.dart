import 'package:wami_core/wami_core.dart';

import '../../domain/entities/referral.dart';

abstract interface class ReferralsRemoteDataSource {
  Future<ReferralOverview> overview();
  Future<String> apply(String code);
  Future<String> validate();
}

int _int(Object? v) => v is num ? v.round() : 0;

/// `/api/drivers/referrals*` + `referralCode` du profil.
class ReferralsApiDataSource implements ReferralsRemoteDataSource {
  const ReferralsApiDataSource(this._api);
  final ApiClient _api;

  @override
  Future<ReferralOverview> overview() async {
    final profile = await _api.get('/api/drivers/profile');
    final list = await _api.get('/api/drivers/referrals');
    final pending = await _api.get('/api/drivers/referrals/my-pending');
    final mine = pending['referralCode'] == null
        ? null
        : MyReferral(
            code: '${pending['referralCode']}',
            status: ReferralStatus.fromApi(pending['status']),
            myReward: _int(pending['referredReward']),
            referrerReward: _int(pending['referrerReward']),
          );
    return ReferralOverview(
      myCode: '${profile['referralCode'] ?? ''}',
      totalPending: _int(list['totalPending']),
      totalValidated: _int(list['totalValidated']),
      mine: mine,
      items: ((list['referrals'] as List<dynamic>?) ?? const []).cast<Map<String, dynamic>>().map((r) {
        return ReferralItem(
          id: '${r['referralId']}',
          name: (r['referredName'] as String?) ?? 'Filleul',
          status: ReferralStatus.fromApi(r['status']),
          reward: _int(r['referrerReward']),
          createdAt: DateTime.tryParse('${r['createdAt']}')?.toLocal() ?? DateTime.now(),
        );
      }).toList(),
    );
  }

  @override
  Future<String> apply(String code) async {
    final j = await _api.post('/api/drivers/referrals/apply', body: {'referralCode': code});
    return (j['message'] as String?) ?? 'Code appliqué.';
  }

  @override
  Future<String> validate() async {
    final j = await _api.post('/api/drivers/referrals/validate');
    return (j['message'] as String?) ?? 'Parrainage validé.';
  }
}

class ReferralsFakeDataSource implements ReferralsRemoteDataSource {
  ReferralsFakeDataSource(this._fake);
  final FakeBackend _fake;

  @override
  Future<ReferralOverview> overview() async {
    await _fake.latency(0.4);
    return ReferralOverview(
      myCode: 'WAMI-DEMO',
      totalPending: 1,
      totalValidated: 2,
      mine: null,
      items: [
        ReferralItem(id: 'p1', name: 'Filleul A', status: ReferralStatus.validated, reward: 2000, createdAt: DateTime.now().subtract(const Duration(days: 10))),
        ReferralItem(id: 'p2', name: 'Filleul B', status: ReferralStatus.pending, reward: 2000, createdAt: DateTime.now().subtract(const Duration(days: 2))),
      ],
    );
  }

  @override
  Future<String> apply(String code) async {
    await _fake.latency(0.4);
    return 'Code appliqué.';
  }

  @override
  Future<String> validate() async {
    await _fake.latency(0.4);
    return 'Parrainage validé.';
  }
}
