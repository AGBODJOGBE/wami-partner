import 'package:equatable/equatable.dart';

/// Palier de bonus (nom, seuil, montant) tel que le serveur le décrit.
class BonusTier extends Equatable {
  const BonusTier({required this.name, this.threshold, this.amount});
  final String name;
  final int? threshold;
  final int? amount;

  @override
  List<Object?> get props => [name, threshold, amount];
}

/// Bonus d'activité du jour : plus on enchaîne de missions, plus le pourcentage monte.
class ActivityBonus extends Equatable {
  const ActivityBonus({
    required this.ridesToday,
    required this.netToday,
    required this.currentTier,
    required this.currentPercent,
    required this.nextTier,
    required this.ridesRemaining,
    required this.estimatedToday,
    required this.provisional,
  });

  final int ridesToday;
  final int netToday;
  final String? currentTier;
  final double currentPercent;
  final String? nextTier;
  final int ridesRemaining;
  final int estimatedToday;
  final bool provisional;

  @override
  List<Object?> get props =>
      [ridesToday, netToday, currentTier, currentPercent, nextTier, ridesRemaining, estimatedToday, provisional];
}

/// Bonus de jalons : paliers du nombre total de missions.
class MilestoneBonus extends Equatable {
  const MilestoneBonus({required this.totalRides, required this.unlocked, required this.next, required this.ridesRemaining});
  final int totalRides;
  final List<BonusTier> unlocked;
  final BonusTier? next;
  final int ridesRemaining;

  @override
  List<Object?> get props => [totalRides, unlocked, next, ridesRemaining];
}

/// Bonus de qualité : note moyenne du mois.
class QualityBonus extends Equatable {
  const QualityBonus({
    required this.ridesThisMonth,
    required this.minRides,
    required this.ridesRemaining,
    required this.averageRating,
    required this.current,
    required this.next,
  });
  final int ridesThisMonth;
  final int minRides;
  final int ridesRemaining;
  final double averageRating;
  final BonusTier? current;
  final BonusTier? next;

  @override
  List<Object?> get props => [ridesThisMonth, minRides, ridesRemaining, averageRating, current, next];
}

/// Vue d'ensemble : chaque bonus est `null` s'il est désactivé ou indisponible.
class BonusOverview extends Equatable {
  const BonusOverview({
    required this.activity,
    required this.milestone,
    required this.quality,
    required this.bonusBalance,
    required this.referralBalance,
  });

  final ActivityBonus? activity;
  final MilestoneBonus? milestone;
  final QualityBonus? quality;

  /// Les bonus et parrainages ne se retirent pas : il faut d'abord les transférer vers le solde principal.
  final int bonusBalance;
  final int referralBalance;

  @override
  List<Object?> get props => [activity, milestone, quality, bonusBalance, referralBalance];
}
