import 'package:dartz/dartz.dart';
import 'package:team_workspace/core/errors/authentication_failure.dart';
import 'package:team_workspace/core/errors/cache_failure.dart';
import 'package:team_workspace/core/errors/failure.dart';
import 'package:team_workspace/core/errors/network_failure.dart';
import 'package:team_workspace/core/errors/server_failure.dart';
import 'package:team_workspace/core/exceptions/cache_exception.dart';
import 'package:team_workspace/features/authentication/data/datasources/auth_local_datasource.dart';
import 'package:team_workspace/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:team_workspace/features/authentication/data/exceptions/auth_exception.dart';
import 'package:team_workspace/features/authentication/data/models/user_model.dart';
import 'package:team_workspace/features/authentication/domain/entities/app_user.dart';
import 'package:team_workspace/features/authentication/domain/repositories/auth_repository.dart';
import 'package:team_workspace/features/task/data/datasources/task_local_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
    required TaskLocalDataSource taskLocalDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _taskLocalDataSource = taskLocalDataSource;

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final TaskLocalDataSource _taskLocalDataSource;

  @override
  Future<Either<Failure, AppUser>> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remoteDataSource.login(
        email: email.trim().toLowerCase(),
        password: password,
      );
      await _clearTaskCacheIfUserChanged(user);
      await _localDataSource.cacheUser(user);
      return Right(user.toEntity());
    } on AuthException catch (e) {
      return Left(_mapException(e));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (_) {
      return const Left(
        ServerFailure(message: 'Something went wrong. Please try again.'),
      );
    }
  }

  @override
  Future<Either<Failure, AppUser>> signup({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remoteDataSource.signup(
        email: email.trim().toLowerCase(),
        password: password,
      );
      await _clearTaskCacheIfUserChanged(user);
      await _localDataSource.cacheUser(user);
      return Right(user.toEntity());
    } on AuthException catch (e) {
      return Left(_mapException(e));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (_) {
      return const Left(
        ServerFailure(message: 'Something went wrong. Please try again.'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remoteDataSource.logout();
      // Keep Hive tasks / mock data for the same account. Cache is cleared only
      // when a different user signs in (see [_clearTaskCacheIfUserChanged]).
      await _localDataSource.clearCachedUser();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(_mapException(e));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (_) {
      return const Left(
        ServerFailure(message: 'Something went wrong. Please try again.'),
      );
    }
  }

  @override
  Future<Either<Failure, AppUser?>> currentUser() async {
    try {
      final user = await _remoteDataSource.getCurrentUser();
      if (user != null) {
        await _clearTaskCacheIfUserChanged(user);
        await _localDataSource.cacheUser(user);
        return Right(user.toEntity());
      }

      // Firebase session missing — clear stale cache.
      await _localDataSource.clearCachedUser();
      return const Right(null);
    } on AuthException catch (e) {
      // Offline / network: restore from Hive so cold start still works.
      final cached = await _tryReadCachedUser();
      if (cached != null) {
        return Right(cached);
      }
      return Left(_mapException(e));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (_) {
      final cached = await _tryReadCachedUser();
      if (cached != null) {
        return Right(cached);
      }
      return const Left(
        ServerFailure(message: 'Something went wrong. Please try again.'),
      );
    }
  }

  Future<AppUser?> _tryReadCachedUser() async {
    try {
      final cached = await _localDataSource.getCachedUser();
      return cached?.toEntity();
    } on CacheException {
      return null;
    }
  }

  /// Drops Hive task/pending data only when [incoming] is a different account.
  ///
  /// Uses the cached user when present, otherwise [AuthLocalDataSource.getLastSessionUid]
  /// so a switch after logout still clears the previous account's offline data.
  Future<void> _clearTaskCacheIfUserChanged(UserModel incoming) async {
    final previous = await _localDataSource.getCachedUser();
    final previousUid =
        previous?.uid ?? await _localDataSource.getLastSessionUid();
    if (previousUid == null || previousUid == incoming.uid) {
      return;
    }
    await _taskLocalDataSource.clearAllTaskCache();
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return _remoteDataSource.authStateChanges().asyncMap((user) async {
      if (user != null) {
        try {
          await _clearTaskCacheIfUserChanged(user);
          await _localDataSource.cacheUser(user);
        } on CacheException {
          // Session stream should still emit even if cache write fails.
        }
        return user.toEntity();
      }

      try {
        ///When Sign-out: drop the session user only. Task cache stays so the same
        /// account can restore offline data on the next login.
        await _localDataSource.clearCachedUser();
      } on CacheException {
        // Ignore cache clear errors on logout stream events.
      }
      return null;
    });
  }

  Failure _mapException(AuthException exception) {
    if (exception.code == 'network-request-failed') {
      return NetworkFailure(message: exception.message);
    }

    const authCodes = {
      'invalid-email',
      'wrong-password',
      'user-not-found',
      'email-already-in-use',
      'weak-password',
      'invalid-credential',
      'user-disabled',
      'operation-not-allowed',
      'too-many-requests',
    };

    if (authCodes.contains(exception.code)) {
      return AuthenticationFailure(message: exception.message);
    }

    return ServerFailure(message: exception.message);
  }
}
