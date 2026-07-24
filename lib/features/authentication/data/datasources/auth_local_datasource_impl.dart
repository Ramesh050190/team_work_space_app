import 'package:team_workspace/core/constants/hive_constants.dart';
import 'package:team_workspace/core/exceptions/cache_exception.dart';
import 'package:team_workspace/core/storage/hive_service.dart';
import 'package:team_workspace/features/authentication/data/datasources/auth_local_datasource.dart';
import 'package:team_workspace/features/authentication/data/models/user_model.dart';

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl({required HiveService hiveService})
    : _hiveService = hiveService;

  final HiveService _hiveService;

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      await _hiveService.userBox.put(HiveConstants.cachedUserKey, user);
      await saveLastSessionUid(user.uid);
    } catch (error) {
      throw CacheException(message: error.toString());
    }
  }

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      return _hiveService.userBox.get(HiveConstants.cachedUserKey);
    } catch (error) {
      throw CacheException(message: error.toString());
    }
  }

  @override
  Future<void> clearCachedUser() async {
    try {
      await _hiveService.userBox.delete(HiveConstants.cachedUserKey);
    } catch (error) {
      throw CacheException(message: error.toString());
    }
  }

  @override
  Future<String?> getLastSessionUid() async {
    try {
      final value = _hiveService.appBox.get(HiveConstants.lastSessionUidKey);
      if (value is String && value.isNotEmpty) return value;
      return null;
    } catch (error) {
      throw CacheException(message: error.toString());
    }
  }

  @override
  Future<void> saveLastSessionUid(String uid) async {
    try {
      await _hiveService.appBox.put(HiveConstants.lastSessionUidKey, uid);
    } catch (error) {
      throw CacheException(message: error.toString());
    }
  }
}
