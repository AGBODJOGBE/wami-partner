import 'package:wami_core/wami_core.dart';

import '../entities/referral.dart';

abstract interface class ReferralsRepository {
  Future<Result<ReferralOverview>> getOverview();

  /// Saisie tardive d'un code de parrainage.
  /// ⚠️ Le serveur refuse probablement cet appel pour un chauffeur (type de parrainage invalide) :
  /// le code se saisit de préférence à l'inscription.
  Future<Result<String>> apply(String code);
  Future<Result<String>> validate();
}
