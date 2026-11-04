import 'package:equatable/equatable.dart';

import '../../../../shared/business_activity.dart';

/// Un lieu géré par le compte (un restaurant, un hôtel, une agence de bus…).
class Establishment extends Equatable {
  const Establishment({
    required this.id,
    required this.name,
    required this.activity,
    required this.district,
    required this.open,
  });

  final String id;
  final String name;
  final BusinessActivity activity;
  final String district;

  /// Ouvert : visible et réservable par les clients.
  final bool open;

  Establishment copyWith({bool? open}) =>
      Establishment(id: id, name: name, activity: activity, district: district, open: open ?? this.open);

  @override
  List<Object?> get props => [id, name, activity, district, open];
}

/// Ce que l'élément « à traiter » ouvre quand on le touche.
enum InboxTarget { activity, reviews, finances }

class InboxItem extends Equatable {
  const InboxItem({required this.title, required this.subtitle, required this.target, this.urgent = false});
  final String title;
  final String subtitle;
  final InboxTarget target;

  /// Demande qui expire bientôt (commande à accepter…).
  final bool urgent;

  @override
  List<Object?> get props => [title, subtitle, target, urgent];
}

/// Tableau de bord d'un établissement.
class DashboardSnapshot extends Equatable {
  const DashboardSnapshot({
    required this.revenueToday,
    required this.activityCount,
    required this.activityLabel,
    required this.rating,
    required this.reviewsCount,
    required this.week,
    required this.weekLabels,
    required this.inbox,
  });

  final int revenueToday;

  /// Commandes, nuitées, visites ou billets du jour, selon l'activité.
  final int activityCount;
  final String activityLabel;
  final double rating;
  final int reviewsCount;

  /// Chiffre d'affaires des 7 derniers jours.
  final List<int> week;
  final List<String> weekLabels;
  final List<InboxItem> inbox;

  int get urgentCount => inbox.where((i) => i.urgent).length;

  @override
  List<Object?> get props => [revenueToday, activityCount, activityLabel, rating, reviewsCount, week, weekLabels, inbox];
}
