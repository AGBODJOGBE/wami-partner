import 'package:wami_core/wami_core.dart';

import '../../../../shared/session_store.dart';
import '../../domain/entities/earnings.dart';

abstract interface class EarningsRemoteDataSource {
  Future<EarningsSummary> earnings(EarningsPeriod period);
  Future<PartnerWallet> wallet();
  Future<PartnerWallet> withdraw(int amount);
  Future<Performance> performance();
  Future<TransferReceipt> transfer(String phone, int amount, String? note);
}

int _int(Object? v) => v is num ? v.round() : 0;
double _rate(Object? v) {
  final d = v is num ? v.toDouble() : 0.0;
  return d > 1 ? d / 100 : d;
}

String _movementLabel(Map<String, dynamic> t) => switch (t['type']) {
      'RIDE_EARNINGS' => 'Course',
      'B2C_EARNINGS' => 'Livraison',
      'COMMISSION' => 'Commission WAMI',
      'B2C_COMMISSION' => 'Commission livraison',
      'WITHDRAWAL' => 'Retrait Mobile Money',
      'BONUS_CREDIT' => 'Bonus',
      'REFERRAL_REWARD' => 'Parrainage',
      'BONUS_EXPIRY' => 'Bonus expiré',
      'CANCELLATION_INDEMNITY' => 'Indemnité d’annulation',
      _ => (t['description'] as String?) ?? 'Mouvement',
    };

/// Portefeuille et gains via `/api/wallets/:walletId/...` (wallet de type EARNINGS).
///
/// Écarts avec le serveur :
/// - pas de route « gains par période » : les gains sont calculés à partir des transactions ;
/// - le solde principal peut être négatif (commission des courses en espèces) : il devient
///   « commission due » et le retrait est bloqué tant qu'il n'est pas couvert ;
/// - le retrait part toujours sur le numéro Mobile Money du compte ; minimum fixé par l'administration.
class EarningsApiDataSource implements EarningsRemoteDataSource {
  const EarningsApiDataSource(this._api, this._session);
  final ApiClient _api;
  final SessionStore _session;

  String get _wallet => '/api/wallets/${_session.requireIdentity.walletId}';

  /// Transactions d'une période, toutes pages confondues (100 par page, 10 pages au plus).
  Future<List<Map<String, dynamic>>> _transactions({DateTime? from, DateTime? to, int max = 1000}) async {
    final all = <Map<String, dynamic>>[];
    var offset = 0;
    while (offset < max) {
      final j = await _api.get('$_wallet/transactions', query: {
        'limit': 100,
        'offset': offset,
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
      });
      final page = ((j['transactions'] as List<dynamic>?) ?? const []).cast<Map<String, dynamic>>();
      all.addAll(page);
      offset += 100;
      if (page.length < 100 || offset >= _int(j['total'])) break;
    }
    return all;
  }

  static const _missionTypes = {'RIDE_EARNINGS', 'B2C_EARNINGS'};
  static const _bonusTypes = {'BONUS_CREDIT', 'REFERRAL_REWARD'};
  static const _commissionTypes = {'COMMISSION', 'B2C_COMMISSION'};

  /// Montant net d'une transaction pour les gains (0 si elle n'en fait pas partie).
  int _earned(Map<String, dynamic> t) {
    if (t['status'] != 'COMPLETED') return 0;
    final type = t['type'];
    final amount = _int(t['amount']);
    if (_missionTypes.contains(type) || _bonusTypes.contains(type)) return t['direction'] == 'DEBIT' ? -amount : amount;
    if (_commissionTypes.contains(type)) return t['direction'] == 'CREDIT' ? amount : -amount;
    return 0;
  }

  @override
  Future<EarningsSummary> earnings(EarningsPeriod period) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    late DateTime start;
    late DateTime previousStart;
    late int buckets;
    late List<String> labels;
    late String range;
    switch (period) {
      case EarningsPeriod.day:
        start = today;
        previousStart = today.subtract(const Duration(days: 1));
        buckets = 6;
        labels = ['0 h', '4 h', '8 h', '12 h', '16 h', '20 h'];
        range = 'Aujourd’hui';
      case EarningsPeriod.week:
        start = today.subtract(Duration(days: today.weekday - 1));
        previousStart = start.subtract(const Duration(days: 7));
        buckets = 7;
        labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
        range = 'Cette semaine';
      case EarningsPeriod.month:
        start = DateTime(now.year, now.month);
        previousStart = DateTime(now.year, now.month - 1);
        buckets = 4;
        labels = ['S1', 'S2', 'S3', 'S4'];
        range = 'Ce mois-ci';
    }
    int bucket(DateTime d) {
      final i = switch (period) {
        EarningsPeriod.day => d.hour ~/ 4,
        EarningsPeriod.week => d.weekday - 1,
        EarningsPeriod.month => (d.day - 1) ~/ 7,
      };
      return i.clamp(0, buckets - 1).toInt();
    }

    final current = await _transactions(from: start, to: now);
    final previous = await _transactions(from: previousStart, to: start);

    final bars = List<int>.filled(buckets, 0);
    var missions = 0;
    var missionCount = 0;
    var bonus = 0;
    var commission = 0;
    for (final t in current) {
      final v = _earned(t);
      if (v == 0) continue;
      final at = DateTime.tryParse('${t['createdAt']}')?.toLocal();
      if (at != null) bars[bucket(at)] += v;
      final type = t['type'];
      if (_missionTypes.contains(type)) {
        missions += v;
        missionCount++;
      } else if (_bonusTypes.contains(type)) {
        bonus += v;
      } else {
        commission += v;
      }
    }
    final previousTotal = previous.fold<int>(0, (sum, t) => sum + _earned(t));
    return EarningsSummary(
      period: period,
      rangeLabel: range,
      total: missions + bonus + commission,
      previousTotal: previousTotal,
      bars: bars,
      barLabels: labels,
      lines: [
        EarningLine('Missions ($missionCount)', missions),
        if (bonus != 0) EarningLine('Bonus', bonus),
        if (commission != 0) EarningLine('Commission WAMI', commission),
      ],
    );
  }

  Future<PartnerWallet> _snapshot() async {
    final b = await _api.get('$_wallet/balance');
    final t = await _api.get('$_wallet/transactions', query: {'limit': 20, 'offset': 0});
    final main = _int(b['mainBalance']);
    final movements = ((t['transactions'] as List<dynamic>?) ?? const []).cast<Map<String, dynamic>>().map((m) {
      final amount = _int(m['amount']);
      return WalletMovement(
        label: _movementLabel(m),
        date: DateTime.tryParse('${m['createdAt']}')?.toLocal() ?? DateTime.now(),
        amount: m['direction'] == 'DEBIT' ? -amount : amount,
      );
    }).toList();
    return PartnerWallet(
      available: main < 0 ? 0 : main,
      cashCommissionDue: main < 0 ? -main : 0,
      payoutMethod: 'Mobile Money · ${_session.requireIdentity.phone}',
      payoutSchedule: 'Retrait à la demande, versé sur votre numéro',
      movements: movements,
    );
  }

  @override
  Future<PartnerWallet> wallet() => _snapshot();

  @override
  Future<PartnerWallet> withdraw(int amount) async {
    await _api.post('$_wallet/withdraw', body: {
      'amount': amount,
      'method': 'MOBILE_MONEY',
      'recipientDetails': {'phone': _session.requireIdentity.phone},
    });
    return _snapshot();
  }

  @override
  Future<TransferReceipt> transfer(String phone, int amount, String? note) async {
    // Le contrôle de solde du serveur compte aussi le bonus ; un transfert de gains ne peut débiter que le solde principal.
    final check = await _api.get('$_wallet/balance/check', query: {'amount': amount});
    if (_int(check['mainBalance']) < amount) {
      throw const BusinessRuleException('insufficient_funds', 'Solde principal insuffisant. Transférez d’abord votre bonus.');
    }
    final j = await _api.post('$_wallet/transfer', body: {
      'recipientPhone': phone.startsWith('+') ? phone : '+229$phone',
      'amount': amount,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    });
    return TransferReceipt(
      sent: _int(j['sentAmount']),
      fee: _int(j['feeAmount']),
      received: _int(j['receivedAmount']),
      remaining: _int(j['senderRemainingBalance']),
    );
  }

  @override
  Future<Performance> performance() async {
    final stats = await _api.get('/api/drivers/stats');
    var done = 0;
    var target = 0;
    var bonus = 0;
    var level = 'Standard';
    var hint = '';
    try {
      final a = await _api.get('/api/driver/bonus/activity/progress');
      done = _int(a['ridesToday']);
      target = done + _int(a['ridesRemainingToNextTier']);
      bonus = _int(a['estimatedBonusToday']);
      level = (a['currentTierName'] as String?) ?? level;
      final next = a['nextTierName'] as String?;
      if (next != null) hint = 'Palier « $next » dans ${_int(a['ridesRemainingToNextTier'])} mission(s)';
    } on Exception {
      // Bonus d'activité désactivé ou indisponible : la performance reste affichée.
    }
    return Performance(
      rating: (stats['averageRating'] as num?)?.toDouble() ?? 0,
      acceptanceRate: _rate(stats['acceptanceRate']),
      cancellationRate: _rate(stats['cancellationRate']),
      goalTarget: target,
      goalDone: done,
      goalBonus: bonus,
      level: level,
      nextLevelHint: hint,
      tags: const {},
    );
  }
}

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
  Future<TransferReceipt> transfer(String phone, int amount, String? note) async {
    await _fake.latency(0.8);
    _available -= amount;
    final fee = (amount * 0.02).round();
    return TransferReceipt(sent: amount, fee: fee, received: amount - fee, remaining: _available);
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
