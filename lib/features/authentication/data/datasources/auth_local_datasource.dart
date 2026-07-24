import 'package:team_workspace/features/authentication/data/models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);

  Future<UserModel?> getCachedUser();

  Future<void> clearCachedUser();

  /// Last account that owned the local task cache (survives logout).
  Future<String?> getLastSessionUid();

  Future<void> saveLastSessionUid(String uid);
}
