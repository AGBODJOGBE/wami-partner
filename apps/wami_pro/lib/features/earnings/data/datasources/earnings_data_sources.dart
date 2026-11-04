import 'package:wami_core/wami_core.dart';

import '../../domain/entities/earnings.dart';

abstract interface class EarningsRemoteDataSource {
  Future<EarningsSummary> earnings(EarningsPeriod period);
  Future<PartnerWallet> wallet();
  Future<PartnerWallet> withdraw(int amount);
  Future<Performance> performance();
}

PartnerWallet _wallet(Map<String, dynamic> j) => PartnerWallet(
      available: j['available'] as int,
      cashCommissionDue: j['cash_commission_due'] as int? ?? 0,
      payoutMethod: j['payout_method'] as String,
      payoutSchedule: j['payout_schedule'] as String? ?? '',
      movements: (j['movements'] as List<dynamic>).cast<Map<String, dynamic>>().map((m) {
        return WalletMovement(label: m['label'] as String, date: DateTime.parse(m['date'] as String), amount: m['amount'] as int);
      }).toList(),
    );

/// Endpoints à valider.
class EarningsApiDataSource implements EarningsRemoteDataSource {
  const EarningsApiDataSource(this._api);
  final ApiClient _api;

  @override
  Future<EarningsSummary> earnings(EarningsPeriod period) async {
    final j = await _api.get('/v1/partner/earnings', query: {'period': period.name});
    return EarningsSummary(
      period: period,
      rangeLabel: j['range_label'] as String,
      total: j['total'] as int,
      previousTotal: j['previous_total'] as int? ?? 0,
      bars: (j['bars'] as List<dynamic>).cast<int>(),
      barLabels: (j['bar_labels'] as List<dynamic>).cast<String>(),
      lines: (j['lines'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((l) => EarningLine(l['label'] as String, l['amount'] as int))
          .toList(),
    );
  }

  @override
  Future<PartnerWallet> wallet() async => _wallet(await _api.get('/v1/partner/wallet'));

  @override
  Future<PartnerWallet> withdraw(int amount) async =>
      _wallet(await _api.post('/v1/partner/wallet/withdrawals', body: {'amount': amount}));

  @override
  Future<Performance> performance() async {
    final j = await _api.get('/v1/partner/performance');
    return Performance(
      rating: (j['rating'] as num).toDouble(),
      acceptanceRate: (j['acceptance_rate'] as num).toDouble(),
      cancellationRate: (j['cancellation_rate'] as num).toDouble(),
      goalTarget: j['goal_target'] as int,
      goalDone: j['goal_done'] as int,
      goalBonus: j['goal_bonus'] as int,
      level: j['level'] as String,
      nextLevelHint: j['next_level_hint'] as String? ?? '',
      tags: (j['tags'] as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int)),
      lastReview: j['last_review'] as String?,
    );
  }
}

/// Données d'exemple.
class EarningsFakeDataSource implements EarningsRemoteDataSource {
  EarningsFakeDataSource(this._fake);
  final FakeBackend _fake;

  int _available = 48750;
  final _movements = <WalletMovement>[
    WalletMovement(label: 'Course · Fidjrossè', date: DateTime.now().subtract(const Duration(hours: 1)), amount: 1509),
    WalletMovement(label: 'Retrait Mobile Money', date: DateTime.now().subtract(const Duration(days: 2)), amount: -52000),
  ];

  @override
  Future<EarningsSummary> earnings(EarningsPeriod period) async {
    await _fake.latency();
    return switch (period) {
      EarningsPeriod.day => const EarningsSummary(
          period: EarningsPeriod.day,
          rangeLabel: 'Aujourd’hui',
          total: 12450,
          previousTotal: 10800,
          bars: [0, 1800, 4200, 2100, 3100, 1250],
          barLabels: ['6 h', '8 h', '10 h', '12 h', '14 h', '16 h'],
          lines: [EarningLine('Missions (8)', 13900), EarningLine('Pourboires', 500), EarningLine('Commission WAMI', -1950)],
        ),
      EarningsPeriod.week => const EarningsSummary(
          period: EarningsPeriod.week,
          rangeLabel: 'Cette semaine',
          total: 74300,
          previousTotal: 66300,
          bars: [9800, 12400, 17800, 11000, 14200, 8000, 1100],
          barLabels: ['L', 'M', 'M', 'J', 'V', 'S', 'D'],
          lines: [
            EarningLine('Missions (41)', 68900),
            EarningLine('Attente et pauses', 2150),
            EarningLine('Pourboires', 3500),
            EarningLine('Bonus objectif', 2000),
            EarningLine('Commission WAMI', -12250),
          ],
        ),
      EarningsPeriod.month => const EarningsSummary(
          period: EarningsPeriod.month,
          rangeLabel: 'Ce mois-ci',
          total: 286400,
          previousTotal: 301000,
          bars: [66300, 74300, 81200, 64600],
          barLabels: ['S1', 'S2', 'S3', 'S4'],
          lines: [EarningLine('Missions (162)', 312000), EarningLine('Bonus', 8000), EarningLine('Commission WAMI', -48600)],
        ),
    };
  }

  PartnerWallet _snapshot() => PartnerWallet(
        available: _available,
        cashCommissionDue: 3200,
        payoutMethod: 'Mobile Money · [Opérateur A] •• 12',
        payoutSchedule: 'Versement automatique chaque [lundi] · à valider',
        movements: List.unmodifiable(_movements),
      );

  @override
  Future<PartnerWallet> wallet() async {
    await _fake.latency(0.6);
    return _snapshot();
  }

  @override
  Future<PartnerWallet> withdraw(int amount) async {
    await _fake.latency(1.5);
    _available -= amount;
    _movements.insert(0, WalletMovement(label: 'Retrait Mobile Money', date: DateTime.now(), amount: -amount));
    return _snapshot();
  }

  @override
  Future<Performance> performance() async {
    await _fake.latency(0.6);
    return const Performance(
      rating: 4.9,
      acceptanceRate: 0.92,
      cancellationRate: 0.02,
      goalTarget: 20,
      goalDone: 14,
      goalBonus: 2000,
      level: 'Argent',
      nextLevelHint: 'Or à 4,9 et 95 % d’acceptation · avantages à valider',
      tags: {'Conduite sûre': 31, 'Ponctuel': 24, 'Sympathique': 18},
      lastReview: 'Très prudent, et il a attendu sans râler.',
    );
  }
}
