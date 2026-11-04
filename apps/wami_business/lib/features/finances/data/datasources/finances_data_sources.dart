import 'package:wami_core/wami_core.dart';

import '../../domain/entities/finances.dart';

abstract interface class FinancesRemoteDataSource {
  Future<FinanceOverview> overview(String establishmentId);
}

Payout _payout(Map<String, dynamic> j) => Payout(
      id: j['id'] as String,
      period: j['period'] as String,
      date: DateTime.parse(j['date'] as String),
      gross: j['gross'] as int,
      commission: j['commission'] as int,
      status: PayoutStatus.values.byName(j['status'] as String),
      method: j['method'] as String,
      adjustments: [
        for (final a in (j['adjustments'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>())
          PayoutLine(a['label'] as String, a['amount'] as int),
      ],
    );

/// Endpoint à valider.
class FinancesApiDataSource implements FinancesRemoteDataSource {
  const FinancesApiDataSource(this._api);
  final ApiClient _api;

  @override
  Future<FinanceOverview> overview(String establishmentId) async {
    final j = await _api.get('/v1/business/establishments/$establishmentId/finances');
    return FinanceOverview(
      pending: j['pending'] as int,
      nextPayoutDate: DateTime.parse(j['next_payout_date'] as String),
      payoutMethod: j['payout_method'] as String,
      commissionRate: (j['commission_rate'] as num).toDouble(),
      months: (j['months'] as List<dynamic>).cast<int>(),
      monthLabels: (j['month_labels'] as List<dynamic>).cast<String>(),
      payouts: [for (final p in (j['payouts'] as List<dynamic>).cast<Map<String, dynamic>>()) _payout(p)],
    );
  }
}

/// Démo : versements hebdomadaires le lundi, commission 12 % (à valider).
class FinancesFakeDataSource implements FinancesRemoteDataSource {
  const FinancesFakeDataSource(this._fake);
  final FakeBackend _fake;

  @override
  Future<FinanceOverview> overview(String establishmentId) async {
    await _fake.latency(0.6);
    final now = DateTime.now();
    final nextMonday = DateTime(now.year, now.month, now.day + (8 - now.weekday));
    DateTime weeksAgo(int w) => DateTime(nextMonday.year, nextMonday.month, nextMonday.day - 7 * w);
    return FinanceOverview(
      pending: 412300,
      nextPayoutDate: nextMonday,
      payoutMethod: 'MTN MoMo · 01 •• •• 42',
      commissionRate: 0.12,
      months: const [1650000, 1820000, 1710000, 2040000, 1980000, 2210000],
      monthLabels: const ['Juin', 'Juil', 'Août', 'Sept', 'Oct', 'Nov'],
      payouts: [
        Payout(
          id: 'p3',
          period: 'Semaine 44',
          date: weeksAgo(1),
          gross: 498000,
          commission: 59760,
          status: PayoutStatus.paid,
          method: 'MTN MoMo',
          adjustments: const [PayoutLine('Commande #A-188 remboursée', -6500)],
        ),
        Payout(id: 'p2', period: 'Semaine 43', date: weeksAgo(2), gross: 521500, commission: 62580, status: PayoutStatus.paid, method: 'MTN MoMo'),
        Payout(
          id: 'p1',
          period: 'Semaine 42',
          date: weeksAgo(3),
          gross: 455000,
          commission: 54600,
          status: PayoutStatus.paid,
          method: 'MTN MoMo',
          adjustments: const [PayoutLine('Geste commercial WAMI', 5000)],
        ),
      ],
    );
  }
}
