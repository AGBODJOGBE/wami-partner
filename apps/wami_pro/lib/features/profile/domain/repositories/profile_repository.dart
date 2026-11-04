import 'package:wami_core/wami_core.dart';

import '../entities/driver_profile.dart';

abstract interface class ProfileRepository {
  Future<Result<DriverProfile>> getProfile();

  /// Applique une modification et renvoie le message du serveur.
  Future<Result<String>> change(ProfileChange change);

  /// Supprime le compte (mot de passe demandé). Le jeton est ensuite révoqué.
  Future<Result<void>> deleteAccount(String password);
}
