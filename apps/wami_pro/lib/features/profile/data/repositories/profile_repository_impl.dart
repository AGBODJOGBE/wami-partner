import 'package:wami_core/wami_core.dart';

import '../../domain/entities/driver_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_data_sources.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._remote);
  final ProfileRemoteDataSource _remote;

  @override
  Future<Result<DriverProfile>> getProfile() => guard(_remote.profile);

  @override
  Future<Result<String>> change(ProfileChange change) => guard(() => _remote.change(change));

  @override
  Future<Result<void>> deleteAccount(String password) => guard(() => _remote.deleteAccount(password));
}
