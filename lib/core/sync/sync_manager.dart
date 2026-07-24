import 'dart:async';

import 'package:dartz/dartz.dart' hide Task;
import 'package:team_workspace/core/connectivity/connectivity_service.dart';
import 'package:team_workspace/core/errors/conflict_failure.dart';
import 'package:team_workspace/core/errors/failure.dart';
import 'package:team_workspace/core/errors/sync_failure.dart';
import 'package:team_workspace/core/exceptions/cache_exception.dart';
import 'package:team_workspace/core/exceptions/network_exception.dart';
import 'package:team_workspace/core/exceptions/server_exception.dart';
import 'package:team_workspace/core/exceptions/timeout_exception.dart';
import 'package:team_workspace/core/logger/app_logger.dart';
import 'package:team_workspace/features/task/data/datasources/task_local_datasource.dart';
import 'package:team_workspace/features/task/data/datasources/task_remote_datasource.dart';
import 'package:team_workspace/features/task/data/models/pending_sync_model.dart';
import 'package:team_workspace/features/task/data/models/task_model.dart';

class SyncResult {
  const SyncResult({
    required this.syncedCount,
    required this.failedCount,
    required this.conflictCount,
    this.message,
  });

  final int syncedCount;
  final int failedCount;
  final int conflictCount;
  final String? message;

  bool get hasFailures => failedCount > 0 || conflictCount > 0;
}

/// Flushes the pending-operations outbox when connectivity returns.
class SyncManager {
  SyncManager({
    required TaskRemoteDataSource remoteDataSource,
    required TaskLocalDataSource localDataSource,
    required ConnectivityService connectivityService,
    required AppLogger logger,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _connectivityService = connectivityService,
       _logger = logger;

  final TaskRemoteDataSource _remoteDataSource;
  final TaskLocalDataSource _localDataSource;
  final ConnectivityService _connectivityService;
  final AppLogger _logger;

  StreamSubscription<bool>? _subscription;
  bool _isSyncing = false;
  void Function(bool isConnected)? onConnectivityChanged;
  void Function(SyncResult result)? onSyncCompleted;
  void Function(Failure failure)? onSyncFailed;

  bool get isSyncing => _isSyncing;

  /// Starts listening for reconnect events (SyncBloc triggers the flush).
  void start() {
    _subscription?.cancel();
    _subscription = _connectivityService.connectionStream.listen((connected) {
      onConnectivityChanged?.call(connected);
    });
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<Either<Failure, SyncResult>> syncPendingChanges() async {
    if (_isSyncing) {
      return const Right(
        SyncResult(
          syncedCount: 0,
          failedCount: 0,
          conflictCount: 0,
          message: 'Sync already in progress',
        ),
      );
    }

    final connected = await _connectivityService.isConnected();
    if (!connected) {
      return const Left(SyncFailure(message: 'Cannot sync while offline.'));
    }

    _isSyncing = true;
    var synced = 0;
    var failed = 0;
    var conflicts = 0;

    /// Maps offline local task ids → server ids after successful creates.
    final localToServerIds = <int, int>{};

    try {
      final pending = await _localDataSource.getPendingOperations();
      for (final rawOperation in pending) {
        final operation = _withResolvedIds(rawOperation, localToServerIds);
        try {
          final conflict = await _executeOperation(
            operation,
            localToServerIds: localToServerIds,
          );
          if (conflict) {
            conflicts++;
          } else {
            synced++;
          }
          await _localDataSource.removePendingOperation(operation.operationId);
        } on CacheException catch (error) {
          failed++;
          _logger.warning('Sync cache error', error);
          await _bumpRetry(operation);
        } on NetworkException catch (error) {
          failed++;
          _logger.warning('Sync network error', error);
          await _bumpRetry(operation);
        } on TimeoutException catch (error) {
          failed++;
          _logger.warning('Sync timeout', error);
          await _bumpRetry(operation);
        } on ServerException catch (error) {
          // 404: task gone on server (stale local id / reset mock store).
          // Drop the op so sync does not retry forever.
          if (error.statusCode == 404) {
            failed++;
            _logger.warning(
              'Dropping pending op ${operation.operationId} '
              '(task ${operation.taskId}): ${error.message}',
              error,
            );
            await _localDataSource.removePendingOperation(
              operation.operationId,
            );
          } else {
            failed++;
            _logger.warning('Sync server error', error);
            await _bumpRetry(operation);
          }
        } on ConflictFailure catch (error) {
          conflicts++;
          _logger.warning('Sync conflict: ${error.message}');
          // Keep local last-write when preferred; still drop the op after apply.
          await _localDataSource.removePendingOperation(operation.operationId);
        } catch (error, stackTrace) {
          failed++;
          _logger.error('Unexpected sync error', error, stackTrace);
          await _bumpRetry(operation);
        }
      }

      final result = SyncResult(
        syncedCount: synced,
        failedCount: failed,
        conflictCount: conflicts,
      );
      onSyncCompleted?.call(result);
      return Right(result);
    } catch (error, stackTrace) {
      _logger.error('Sync failed', error, stackTrace);
      const failure = SyncFailure();
      onSyncFailed?.call(failure);
      return const Left(failure);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _bumpRetry(PendingSyncModel operation) async {
    await _localDataSource.updatePendingOperation(
      operation.copyWith(retryCount: operation.retryCount + 1),
    );
  }

  /// Applies in-memory local→server id remaps to a queued operation.
  PendingSyncModel _withResolvedIds(
    PendingSyncModel operation,
    Map<int, int> localToServerIds,
  ) {
    final resolvedId = localToServerIds[operation.taskId] ?? operation.taskId;
    if (resolvedId == operation.taskId) {
      return operation;
    }

    final payload = Map<String, dynamic>.from(operation.payload);
    if (payload['id'] == operation.taskId) {
      payload['id'] = resolvedId;
    }
    return operation.copyWith(taskId: resolvedId, payload: payload);
  }

  /// Returns `true` when a conflict was resolved using last-modified wins.
  Future<bool> _executeOperation(
    PendingSyncModel operation, {
    required Map<int, int> localToServerIds,
  }) async {
    switch (operation.operationType) {
      case PendingOperationType.create:
        final localTask = TaskModel.fromJson(operation.payload);
        final localId = operation.taskId;
        final created = await _remoteDataSource.createTask(localTask);
        localToServerIds[localId] = created.id;
        await _localDataSource.replaceCachedTaskId(
          localId: localId,
          serverTask: created,
        );
        _logger.info(
          'Synced create: local id $localId → server id ${created.id}',
        );
        return false;

      case PendingOperationType.update:
        final localTask = TaskModel.fromJson(
          operation.payload,
        ).copyWith(id: operation.taskId);
        final resolved = await _resolveConflict(localTask);
        final updated = await _remoteDataSource.updateTask(resolved.task);
        await _localDataSource.cacheTaskDetails(updated);
        return resolved.hadConflict;

      case PendingOperationType.statusChange:
        final completed = operation.payload['completed'] as bool? ?? false;
        final updated = await _remoteDataSource.updateTaskStatus(
          id: operation.taskId,
          completed: completed,
        );
        await _localDataSource.cacheTaskDetails(updated);
        return false;

      case PendingOperationType.delete:
        await _localDataSource.removeCachedTask(operation.taskId);
        return false;
    }
  }

  Future<({TaskModel task, bool hadConflict})> _resolveConflict(
    TaskModel localTask,
  ) async {
    try {
      final remoteTask = await _remoteDataSource.getTaskDetails(localTask.id);
      if (remoteTask.updatedAt.isAfter(localTask.updatedAt)) {
        _logger.warning(
          'Conflict for task ${localTask.id}: remote newer '
          '(${remoteTask.updatedAt} > ${localTask.updatedAt}). '
          'Preferring last-modified remote version.',
        );
        await _localDataSource.cacheTaskDetails(remoteTask);
        throw ConflictFailure(
          message:
              'Remote version is newer for task ${localTask.id}. Kept remote.',
          localUpdatedAt: localTask.updatedAt,
          remoteUpdatedAt: remoteTask.updatedAt,
        );
      }
      if (localTask.updatedAt.isAfter(remoteTask.updatedAt)) {
        _logger.info(
          'Conflict for task ${localTask.id}: local newer. Preferring local.',
        );
        return (task: localTask, hadConflict: true);
      }
    } on ConflictFailure {
      rethrow;
    } on ServerException catch (error) {
      // Missing remote task — proceed with local payload (e.g. just created).
      if (error.statusCode != 404) {
        _logger.warning(
          'Conflict check failed for task ${localTask.id}',
          error,
        );
      }
    } catch (_) {
      // If remote fetch fails, proceed with local payload.
    }
    return (task: localTask, hadConflict: false);
  }
}
