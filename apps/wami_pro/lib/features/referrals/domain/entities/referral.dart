import 'package:equatable/equatable.dart';

enum ReferralStatus {
  pending('En attente'),
  validated('Validé'),
  expired('Expiré');

  const ReferralStatus(this.label);
  final String label;

  static ReferralStatus fromApi(Object? v) => switch (v) {
        'VALIDATED' => validated,
        'EXPIRED' => expired,
        _ => pending,
      };
}

class ReferralItem extends Equatable {
  const ReferralItem({required this.id, required this.name, required this.status, required this.reward, required this.createdAt});
  final String id;
  final String name;
  final ReferralStatus status;

  /// Récompense du parrain en FCFA.
  final int reward;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, name, status, reward, createdAt];
}

/// Parrainage dont le chauffeur est lui-même le filleul (code utilisé à l'inscription).
class MyReferral extends Equatable {
  const MyReferral({required this.code, required this.status, required this.myReward, required this.referrerReward});
  final String code;
  final ReferralStatus status;
  final int myReward;
  final int referrerReward;

  @override
  List<Object?> get props => [code, status, myReward, referrerReward];
}

class ReferralOverview extends Equatable {
  const ReferralOverview({
    required this.myCode,
    required this.items,
    required this.totalPending,
    required this.totalValidated,
    required this.mine,
  });

  /// Code à partager (celui du chauffeur).
  final String myCode;
  final List<ReferralItem> items;
  final int totalPending;
  final int totalValidated;
  final MyReferral? mine;

  @override
  List<Object?> get props => [myCode, items, totalPending, totalValidated, mine];
}
