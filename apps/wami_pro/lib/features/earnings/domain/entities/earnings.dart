import 'package:equatable/equatable.dart';

enum EarningsPeriod {
  day('Jour'),
  week('Semaine'),
  month('Mois');

  const EarningsPeriod(this.label);
  final String label;
}

class EarningLine extends Equatable {
  const EarningLine(this.label, this.amount);
  final String label;

  /// Signé : la commission est négative.
  final int amount;

  @override
  List<Object?> get props => [label, amount];
}

class EarningsSummary extends Equatable {
  const EarningsSummary({
    required this.period,
    required this.rangeLabel,
    required this.total,
    required this.previousTotal,
    required this.bars,
    required this.barLabels,
    required this.lines,
  });

  final EarningsPeriod period;
  final String rangeLabel;
  final int total;
  final int previousTotal;
  final List<int> bars;
  final List<String> barLabels;
  final List<EarningLine> lines;

  /// Évolution en % par rapport à la période précédente.
  int get trendPercent => previousTotal == 0 ? 0 : (((total - previousTotal) / previousTotal) * 100).round();

  int get bestIndex {
    var best = 0;
    for (var i = 1; i < bars.length; i++) {
      if (bars[i] > bars[best]) best = i;
    }
    return best;
  }

  @override
  List<Object?> get props => [period, rangeLabel, total, previousTotal, bars, barLabels, lines];
}

class WalletMovement extends Equatable {
  const WalletMovement({required this.label, required this.date, required this.amount});
  final String label;
  final DateTime date;
  final int amount;

  @override
  List<Object?> get props => [label, date, amount];
}

class PartnerWallet extends Equatable {
  const PartnerWallet({
    required this.available,
    required this.cashCommissionDue,
    required this.payoutMethod,
    required this.payoutSchedule,
    required this.movements,
  });

  final int available;

  /// Commission due sur les courses payées en espèces (déduite au retrait).
  final int cashCommissionDue;
  final String payoutMethod;
  final String payoutSchedule;
  final List<WalletMovement> movements;

  int get withdrawable => (available - cashCommissionDue).clamp(0, available);

  @override
  List<Object?> get props => [available, cashCommissionDue, payoutMethod, payoutSchedule, movements];
}

class Performance extends Equatable {
  const Performance({
    required this.rating,
    required this.acceptanceRate,
    required this.cancellationRate,
    required this.goalTarget,
    required this.goalDone,
    required this.goalBonus,
    required this.level,
    required this.nextLevelHint,
    required this.tags,
    this.lastReview,
  });

  final double rating;
  final double acceptanceRate;
  final double cancellationRate;
  final int goalTarget;
  final int goalDone;
  final int goalBonus;
  final String level;
  final String nextLevelHint;
  final Map<String, int> tags;
  final String? lastReview;

  double get goalProgress => goalTarget == 0 ? 0 : (goalDone / goalTarget).clamp(0, 1).toDouble();

  @override
  List<Object?> get props =>
      [rating, acceptanceRate, cancellationRate, goalTarget, goalDone, goalBonus, level, nextLevelHint, tags, lastReview];
}
