import 'package:dartz/dartz.dart';
import 'package:team_workspace/core/errors/cache_failure.dart';
import 'package:team_workspace/core/errors/failure.dart';
import 'package:team_workspace/core/errors/network_failure.dart';
import 'package:team_workspace/core/errors/server_failure.dart';
import 'package:team_workspace/core/errors/timeout_failure.dart';
import 'package:team_workspace/core/errors/unknown_failure.dart';
import 'package:team_workspace/core/exceptions/cache_exception.dart';
import 'package:team_workspace/core/exceptions/network_exception.dart';
import 'package:team_workspace/core/exceptions/server_exception.dart';
import 'package:team_workspace/core/exceptions/timeout_exception.dart';
import 'package:team_workspace/core/network/network_info.dart';
import 'package:team_workspace/features/dashboard/data/datasources/dashboard_local_datasource.dart';
import 'package:team_workspace/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:team_workspace/features/dashboard/domain/entities/paginated_tasks_page.dart';
import 'package:team_workspace/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';

/// Offline-first dashboard repository.
class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({
    required DashboardRemoteDataSource remoteDataSource,
    required DashboardLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _networkInfo = networkInfo;

  final DashboardRemoteDataSource _remoteDataSource;
  final DashboardLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  @override
  Future<Either<Failure, PaginatedTasksPage>> getTasks({
    required int page,
    required int limit,
    bool cacheOnly = false,
    String searchQuery = '',
    TaskStatus? status,
    TaskPriority? priority,
  }) async {
    if (cacheOnly) {
      return _readCache(
        page: page,
        limit: limit,
        searchQuery: searchQuery,
        status: status,
        priority: priority,
      );
    }

    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) {
      return _readCacheOrFail(
        page: page,
        limit: limit,
        searchQuery: searchQuery,
        status: status,
        priority: priority,
        fallback: const NetworkFailure(message: 'No internet connection'),
      );
    }

    try {
      final response = await _remoteDataSource.getTasks(
        page: page,
        limit: limit,
        searchQuery: searchQuery,
        status: status,
        priority: priority,
      );
      try {
        await _localDataSource.cacheTasks(response.tasks, page: page);
      } on CacheException {
        // Remote success still returns even if cache write fails.
      }

      return Right(
        PaginatedTasksPage(
          tasks: response.tasks.map((task) => task.toEntity()).toList(),
          page: response.page,
          totalPages: response.totalPages,
        ),
      );
    } on NetworkException catch (error) {
      return _readCacheOrFail(
        page: page,
        limit: limit,
        searchQuery: searchQuery,
        status: status,
        priority: priority,
        fallback: NetworkFailure(message: error.message),
      );
    } on TimeoutException catch (error) {
      return _readCacheOrFail(
        page: page,
        limit: limit,
        searchQuery: searchQuery,
        status: status,
        priority: priority,
        fallback: TimeoutFailure(message: error.message),
      );
    } on ServerException catch (error) {
      return _readCacheOrFail(
        page: page,
        limit: limit,
        searchQuery: searchQuery,
        status: status,
        priority: priority,
        fallback: ServerFailure(
          message: error.message,
          statusCode: error.statusCode,
        ),
      );
    } on CacheException catch (error) {
      return Left(CacheFailure(message: error.message));
    } catch (_) {
      return _readCacheOrFail(
        page: page,
        limit: limit,
        searchQuery: searchQuery,
        status: status,
        priority: priority,
        fallback: const UnknownFailure(),
      );
    }
  }

  Future<Either<Failure, PaginatedTasksPage>> _readCache({
    required int page,
    required int limit,
    String searchQuery = '',
    TaskStatus? status,
    TaskPriority? priority,
  }) async {
    try {
      final cached = await _localDataSource.getCachedTasks(
        page: page,
        limit: limit,
        searchQuery: searchQuery,
        status: status,
        priority: priority,
      );
      if (cached.tasks.isEmpty && page == 1) {
        return const Left(CacheFailure(message: 'No cached tasks available'));
      }
      return Right(cached);
    } on CacheException catch (error) {
      return Left(CacheFailure(message: error.message));
    } catch (_) {
      return const Left(CacheFailure(message: 'Failed to read task cache'));
    }
  }

  Future<Either<Failure, PaginatedTasksPage>> _readCacheOrFail({
    required int page,
    required int limit,
    String searchQuery = '',
    TaskStatus? status,
    TaskPriority? priority,
    required Failure fallback,
  }) async {
    final cached = await _readCache(
      page: page,
      limit: limit,
      searchQuery: searchQuery,
      status: status,
      priority: priority,
    );
    return cached.fold((_) => Left(fallback), Right.new);
  }
}
