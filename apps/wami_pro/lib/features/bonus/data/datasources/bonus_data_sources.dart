import 'package:wami_core/wami_core.dart';

import '../../../../shared/session_store.dart';
import '../../domain/entities/bonus.dart';

abstract interface class BonusRemoteDataSource {
  Future<BonusOverview> overview();
  Future<void> consolidate(int amount);
}

int _int(Object? v) => v is num ? v.round() : 0;

BonusTier? _tier(Object? j) {
  if (j is! Map) return null;
  return BonusTier(
    name: (j['name'] as String?) ?? '',
    threshold: (j['ridesThreshold'] ?? j['minRating']) is num ? _int(j['ridesThreshold'] ?? j['minRating']) : null,
    amount: j['bonusAmount'] is num ? _int(j['bonusAmount']) : null,
  );
}

/// Routes `/api/driver/bonus/*` et solde du wallet. Un bonus désactivé par
/// l'administration (`...Enabled: false`) ou une route en erreur donne `null` :
/// la page n'affiche alors pas la carte correspondante.
class BonusApiDataSource implements BonusRemoteDataSource {
  const BonusApiDataSource(this._api, this._session);
  final ApiClient _api;
  final SessionStore _session;

  Future<Map<String, dynamic>?> _try(String path) async {
    try {
      return await _api.get(path);
    } on Exception {
      return null;
    }
  }

  @override
  Future<BonusOverview> overview() async {
    final a = await _try('/api/driver/bonus/activity/progress');
    final m = await _try('/api/driver/bonus/milestone/progress');
    final q = await _try('/api/driver/bonus/quality/progress');
    final b = await _api.get('/api/wallets/${_session.requireIdentity.walletId}/balance');
    return BonusOverview(
      activity: a == null || a['activityBonusEnabled'] != true
          ? null
          : ActivityBonus(
              ridesToday: _int(a['ridesToday']),
              netToday: _int(a['netToday']),
              currentTier: a['currentTierName'] as String?,
              currentPercent: (a['currentPct'] as num?)?.toDouble() ?? 0,
              nextTier: a['nextTierName'] as String?,
              ridesRemaining: _int(a['ridesRemainingToNextTier']),
              estimatedToday: _int(a['estimatedBonusToday']),
              provisional: a['isProvisional'] == true,
            ),
      milestone: m == null || m['milestoneBonusEnabled'] != true
          ? null
          : MilestoneBonus(
              totalRides: _int(m['totalLifetimeRides']),
              unlocked: ((m['unlockedTiers'] as List<dynamic>?) ?? const []).map(_tier).whereType<BonusTier>().toList(),
              next: _tier(m['nextTier']),
              ridesRemaining: _int(m['ridesRemaining']),
            ),
      quality: q == null || q['qualityBonusEnabled'] != true
          ? null
          : QualityBonus(
              ridesThisMonth: _int(q['ridesThisMonth']),
              minRides: _int(q['minRidesRequired']),
              ridesRemaining: _int(q['ridesRemaining']),
              averageRating: (q['currentAvgRating'] as num?)?.toDouble() ?? 0,
              current: _tier(q['currentTier']),
              next: _tier(q['nextTier']),
            ),
      bonusBalance: _int(b['bonusBalance']),
      referralBalance: _int(b['referralBalance']),
    );
  }

  @override
  Future<void> consolidate(int amount) => _api.post(
        '/api/wallets/${_session.requireIdentity.walletId}/consolidate',
        body: {'fromBalance': 'BONUS', 'amount': amount},
      );
}

class BonusFakeDataSource implements BonusRemoteDataSource {
  BonusFakeDataSource(this._fake);
  final FakeBackend _fake;

  int _balance = 3500;

  @override
  Future<BonusOverview> overview() async {
    await _fake.latency(0.5);
    return BonusOverview(
      activity: const ActivityBonus(
        ridesToday: 6,
        netToday: 12450,
        currentTier: 'Argent',
        currentPercent: 3,
        nextTier: 'Or',
        ridesRemaining: 2,
        estimatedToday: 370,
        provisional: true,
      ),
      milestone: const MilestoneBonus(
        totalRides: 162,
        unlocked: [BonusTier(name: '100 missions', threshold: 100, amount: 5000)],
        next: BonusTier(name: '250 missions', threshold: 250, amount: 10000),
        ridesRemaining: 88,
      ),
      quality: const QualityBonus(
        ridesThisMonth: 41,
        minRides: 30,
        ridesRemaining: 0,
        averageRating: 4.8,
        current: BonusTier(name: 'Qualité', threshold: 5, amount: 2000),
        next: null,
      ),
      bonusBalance: _balance,
      referralBalance: 0,
    );
  }

  @override
  Future<void> consolidate(int amount) async {
    await _fake.latency(0.8);
    _balance = (_balance - amount).clamp(0, _balance).toInt();
  }
}
