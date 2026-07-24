import 'package:dartz/dartz.dart' hide Task;
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
import 'package:team_workspace/features/dashboard/domain/entities/paginated_tasks.dart';
import 'package:team_workspace/features/dashboard/domain/entities/task_query.dart';
import 'package:team_workspace/features/dashboard/domain/utils/task_query_matcher.dart';
import 'package:team_workspace/features/task/data/datasources/task_local_datasource.dart';
import 'package:team_workspace/features/task/data/datasources/task_remote_datasource.dart';
import 'package:team_workspace/features/task/data/models/pending_sync_model.dart';
import 'package:team_workspace/features/task/data/models/task_model.dart';
import 'package:team_workspace/features/task/domain/entities/task.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';
import 'package:team_workspace/features/task/domain/repositories/task_repository.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl({
    required TaskRemoteDataSource remoteDataSource,
    required TaskLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _networkInfo = networkInfo;

  final TaskRemoteDataSource _remoteDataSource;
  final TaskLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  @override
  Future<Either<Failure, Task>> getTaskDetails(int id) async {
    final isConnected = await _networkInfo.isConnected;

    // Cache-first: prefer local snapshot when present.
    TaskModel? cached;
    try {
      cached = await _localDataSource.getCachedTaskDetails(id);
    } on CacheException {
      cached = null;
    }

    if (!isConnected) {
      if (cached != null) {
        return Right(cached.toEntity());
      }
      return const Left(NetworkFailure());
    }

    try {
      final remoteTask = await _remoteDataSource.getTaskDetails(id);
      if (cached != null && cached.updatedAt.isAfter(remoteTask.updatedAt)) {
        // Prefer fresher local edits that may still be pending sync.
        return Right(cached.toEntity());
      }
      await _localDataSource.cacheTaskDetails(remoteTask);
      return Right(remoteTask.toEntity());
    } on NetworkException catch (error) {
      return _loadFromCacheOrFail(id, NetworkFailure(message: error.message));
    } on TimeoutException catch (error) {
      return _loadFromCacheOrFail(id, TimeoutFailure(message: error.message));
    } on ServerException catch (error) {
      return _loadFromCacheOrFail(
        id,
        ServerFailure(message: error.message, statusCode: error.statusCode),
      );
    } on CacheException catch (error) {
      return Left(CacheFailure(message: error.message));
    } catch (_) {
      return _loadFromCacheOrFail(id, const UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, Task>> updateTaskStatus({
    required int id,
    required bool completed,
  }) async {
    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) {
      return _queueStatusChange(id: id, completed: completed);
    }

    try {
      final updatedTask = await _remoteDataSource.updateTaskStatus(
        id: id,
        completed: completed,
      );
      await _localDataSource.cacheTaskDetails(updatedTask);
      return Right(updatedTask.toEntity());
    } on NetworkException catch (error) {
      return _queueStatusChange(
        id: id,
        completed: completed,
        fallbackFailure: NetworkFailure(message: error.message),
      );
    } on TimeoutException catch (error) {
      return _queueStatusChange(
        id: id,
        completed: completed,
        fallbackFailure: TimeoutFailure(message: error.message),
      );
    } on ServerException catch (error) {
      return Left(
        ServerFailure(message: error.message, statusCode: error.statusCode),
      );
    } on CacheException catch (error) {
      return Left(CacheFailure(message: error.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, Task>> createTask(Task task) async {
    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) {
      return _queueCreate(task);
    }

    try {
      final created = await _remoteDataSource.createTask(
        TaskModel.fromEntity(task),
      );
      await _localDataSource.cacheTaskDetails(created);
      return Right(created.toEntity());
    } on NetworkException catch (error) {
      return _queueCreate(
        task,
        fallbackFailure: NetworkFailure(message: error.message),
      );
    } on TimeoutException catch (error) {
      return _queueCreate(
        task,
        fallbackFailure: TimeoutFailure(message: error.message),
      );
    } on ServerException catch (error) {
      return Left(
        ServerFailure(message: error.message, statusCode: error.statusCode),
      );
    } on CacheException catch (error) {
      return Left(CacheFailure(message: error.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, Task>> updateTask(Task task) async {
    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) {
      return _queueUpdate(task);
    }

    try {
      final updated = await _remoteDataSource.updateTask(
        TaskModel.fromEntity(task),
      );
      await _localDataSource.cacheTaskDetails(updated);
      return Right(updated.toEntity());
    } on NetworkException catch (error) {
      return _queueUpdate(
        task,
        fallbackFailure: NetworkFailure(message: error.message),
      );
    } on TimeoutException catch (error) {
      return _queueUpdate(
        task,
        fallbackFailure: TimeoutFailure(message: error.message),
      );
    } on ServerException catch (error) {
      return Left(
        ServerFailure(message: error.message, statusCode: error.statusCode),
      );
    } on CacheException catch (error) {
      return Left(CacheFailure(message: error.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, PaginatedTasks>> searchTasks(TaskQuery query) {
    return _queryTasks(query);
  }

  @override
  Future<Either<Failure, PaginatedTasks>> filterTasks(TaskQuery query) {
    return _queryTasks(query);
  }

  Future<Either<Failure, PaginatedTasks>> _queryTasks(TaskQuery query) async {
    final isConnected = await _networkInfo.isConnected;

    if (isConnected) {
      try {
        final remote = await _remoteDataSource.queryTasks(query);
        if (query.page == 1) {
          await _cacheMergedPage(remote.tasks);
        } else {
          for (final task in remote.tasks) {
            await _localDataSource.cacheTaskDetails(task);
          }
        }

        return Right(
          PaginatedTasks(
            tasks: remote.tasks.map((task) => task.toEntity()).toList(),
            page: remote.page,
            limit: remote.limit,
            total: remote.total,
            hasMore: remote.hasMore,
          ),
        );
      } on NetworkException catch (error) {
        return _queryFromCacheOrFail(
          query,
          NetworkFailure(message: error.message),
        );
      } on TimeoutException catch (error) {
        return _queryFromCacheOrFail(
          query,
          TimeoutFailure(message: error.message),
        );
      } on ServerException catch (error) {
        return _queryFromCacheOrFail(
          query,
          ServerFailure(message: error.message, statusCode: error.statusCode),
        );
      } on CacheException catch (error) {
        return Left(CacheFailure(message: error.message));
      } catch (_) {
        return _queryFromCacheOrFail(query, const UnknownFailure());
      }
    }

    return _queryFromCacheOrFail(query, const NetworkFailure());
  }

  Future<Either<Failure, Task>> _queueCreate(
    Task task, {
    Failure? fallbackFailure,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      final localId = task.id > 0 ? task.id : -now.microsecondsSinceEpoch;
      final localTask = TaskModel.fromEntity(
        task.copyWith(id: localId, createdAt: task.createdAt, updatedAt: now),
      );
      await _localDataSource.cacheTaskDetails(localTask);
      await _localDataSource.enqueuePendingOperation(
        PendingSyncModel(
          operationId: _operationId(localId, PendingOperationType.create),
          taskId: localId,
          operationType: PendingOperationType.create,
          payload: localTask.toJson(),
          createdAt: now,
        ),
      );
      return Right(localTask.toEntity());
    } on CacheException catch (error) {
      return Left(fallbackFailure ?? CacheFailure(message: error.message));
    }
  }

  Future<Either<Failure, Task>> _queueUpdate(
    Task task, {
    Failure? fallbackFailure,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      final localTask = TaskModel.fromEntity(task.copyWith(updatedAt: now));
      await _localDataSource.cacheTaskDetails(localTask);
      await _localDataSource.enqueuePendingOperation(
        PendingSyncModel(
          operationId: _operationId(task.id, PendingOperationType.update),
          taskId: task.id,
          operationType: PendingOperationType.update,
          payload: localTask.toJson(),
          createdAt: now,
        ),
      );
      return Right(localTask.toEntity());
    } on CacheException catch (error) {
      return Left(fallbackFailure ?? CacheFailure(message: error.message));
    }
  }

  Future<Either<Failure, Task>> _queueStatusChange({
    required int id,
    required bool completed,
    Failure? fallbackFailure,
  }) async {
    try {
      final existing = await _localDataSource.getCachedTaskDetails(id);
      if (existing == null) {
        return Left(
          fallbackFailure ??
              const CacheFailure(message: 'No cached task to update offline.'),
        );
      }

      final now = DateTime.now().toUtc();
      final localTask = existing.copyWith(
        completed: completed,
        status: completed ? TaskStatus.completed : TaskStatus.pending,
        updatedAt: now,
      );
      await _localDataSource.cacheTaskDetails(localTask);
      await _localDataSource.enqueuePendingOperation(
        PendingSyncModel(
          operationId: _operationId(id, PendingOperationType.statusChange),
          taskId: id,
          operationType: PendingOperationType.statusChange,
          payload: {'completed': completed, 'updatedAt': now.toIso8601String()},
          createdAt: now,
        ),
      );
      return Right(localTask.toEntity());
    } on CacheException catch (error) {
      return Left(fallbackFailure ?? CacheFailure(message: error.message));
    }
  }

  String _operationId(int taskId, PendingOperationType type) {
    return '${type.name}_${taskId}_${DateTime.now().microsecondsSinceEpoch}';
  }

  Future<void> _cacheMergedPage(List<TaskModel> pageTasks) async {
    final existing = await _localDataSource.getCachedTaskList();
    final byId = <int, TaskModel>{for (final task in existing) task.id: task};
    for (final task in pageTasks) {
      final current = byId[task.id];
      // Never overwrite a fresher local pending edit with older server data.
      if (current != null && current.updatedAt.isAfter(task.updatedAt)) {
        continue;
      }
      byId[task.id] = task;
    }
    await _localDataSource.cacheTaskList(byId.values.toList(growable: false));
  }

  Future<Either<Failure, PaginatedTasks>> _queryFromCacheOrFail(
    TaskQuery query,
    Failure remoteFailure,
  ) async {
    try {
      final cached = await _localDataSource.getCachedTaskList();
      if (cached.isEmpty) {
        return Left(remoteFailure);
      }

      final entities = cached.map((model) => model.toEntity()).toList();
      final filtered = TaskQueryMatcher.apply(entities, query);
      final pageItems = TaskQueryMatcher.paginate(
        filtered,
        page: query.page,
        limit: query.limit,
      );
      final hasMore = query.page * query.limit < filtered.length;

      return Right(
        PaginatedTasks(
          tasks: pageItems,
          page: query.page,
          limit: query.limit,
          total: filtered.length,
          hasMore: hasMore,
        ),
      );
    } on CacheException catch (error) {
      return Left(CacheFailure(message: error.message));
    }
  }

  Future<Either<Failure, Task>> _loadFromCacheOrFail(
    int id,
    Failure remoteFailure,
  ) async {
    try {
      final cachedTask = await _localDataSource.getCachedTaskDetails(id);
      if (cachedTask != null) {
        return Right(cachedTask.toEntity());
      }
      return Left(remoteFailure);
    } on CacheException catch (error) {
      return Left(CacheFailure(message: error.message));
    }
  }
}
