import 'dart:convert';

import 'package:team_workspace/core/constants/hive_constants.dart';
import 'package:team_workspace/core/exceptions/cache_exception.dart';
import 'package:team_workspace/core/network/mock_task_interceptor.dart';
import 'package:team_workspace/core/storage/hive_service.dart';
import 'package:team_workspace/features/task/data/datasources/task_local_datasource.dart';
import 'package:team_workspace/features/task/data/models/pending_sync_model.dart';
import 'package:team_workspace/features/task/data/models/task_model.dart';

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  TaskLocalDataSourceImpl({required HiveService hiveService})
    : _hiveService = hiveService;

  final HiveService _hiveService;

  String _cacheKey(int id) => 'task_details_$id';

  /// Hive int keys must be 0–0xFFFFFFFF; offline local ids are negative /
  /// larger than that, so always key [tasksBox] with strings.
  String _taskKey(int id) => id.toString();

  @override
  Future<void> cacheTaskDetails(TaskModel task) async {
    try {
      await _hiveService.taskDetailsBox.put(
        _cacheKey(task.id),
        jsonEncode(task.toJson()),
      );
      // Keep typed lazy box in sync for adapter-backed lookups.
      await _hiveService.tasksBox.put(_taskKey(task.id), task);
      await upsertCachedTask(task);
    } catch (error) {
      throw CacheException(message: error.toString());
    }
  }

  @override
  Future<TaskModel?> getCachedTaskDetails(int id) async {
    try {
      final cached = _hiveService.taskDetailsBox.get(_cacheKey(id));
      if (cached != null) {
        final json = jsonDecode(cached) as Map<String, dynamic>;
        return TaskModel.fromJson(json);
      }

      return _hiveService.tasksBox.get(_taskKey(id));
    } catch (error) {
      throw CacheException(message: error.toString());
    }
  }

  @override
  Future<void> clearTaskDetails(int id) async {
    try {
      await _hiveService.taskDetailsBox.delete(_cacheKey(id));
      await _hiveService.tasksBox.delete(_taskKey(id));
    } catch (error) {
      throw CacheException(message: error.toString());
    }
  }

  @override
  Future<void> cacheTaskList(List<TaskModel> tasks) async {
    try {
      final payload = tasks.map((task) => task.toJson()).toList();
      await _hiveService.taskListBox.put(
        HiveConstants.taskListCacheKey,
        jsonEncode(payload),
      );

      for (final task in tasks) {
        await _hiveService.taskDetailsBox.put(
          _cacheKey(task.id),
          jsonEncode(task.toJson()),
        );
        await _hiveService.tasksBox.put(_taskKey(task.id), task);
      }
    } catch (error) {
      throw CacheException(message: error.toString());
    }
  }

  @override
  Future<List<TaskModel>> getCachedTaskList() async {
    try {
      final cached = await _hiveService.taskListBox.get(
        HiveConstants.taskListCacheKey,
      );
      if (cached == null) return const [];

      final decoded = jsonDecode(cached) as List<dynamic>;
      return decoded
          .map(
            (item) =>
                TaskModel.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(growable: false);
    } catch (error) {
      throw CacheException(message: error.toString());
    }
  }

  @override
  Future<void> upsertCachedTask(TaskModel task) async {
    try {
      final current = List<TaskModel>.from(await getCachedTaskList());
      final index = current.indexWhere((item) => item.id == task.id);
      if (index >= 0) {
        current[index] = task;
      } else {
        current.insert(0, task);
      }

      final payload = current.map((item) => item.toJson()).toList();
      await _hiveService.taskListBox.put(
        HiveConstants.taskListCacheKey,
        jsonEncode(payload),
      );
      await _hiveService.tasksBox.put(_taskKey(task.id), task);
      await _hiveService.taskDetailsBox.put(
        _cacheKey(task.id),
        jsonEncode(task.toJson()),
      );
    } catch (error) {
      throw CacheException(message: error.toString());
    }
  }

  @override
  Future<void> removeCachedTask(int taskId) async {
    try {
      await clearTaskDetails(taskId);
      final current = List<TaskModel>.from(await getCachedTaskList())
        ..removeWhere((task) => task.id == taskId);
      final payload = current.map((item) => item.toJson()).toList();
      await _hiveService.taskListBox.put(
        HiveConstants.taskListCacheKey,
        jsonEncode(payload),
      );
    } catch (error) {
      throw CacheException(message: error.toString());
    }
  }

  @override
  Future<void> replaceCachedTaskId({
    required int localId,
    required TaskModel serverTask,
  }) async {
    try {
      await removeCachedTask(localId);
      await cacheTaskDetails(serverTask);
      await remapPendingTaskId(localId: localId, serverId: serverTask.id);
    } catch (error) {
      throw CacheException(message: error.toString());
    }
  }

  @override
  Future<void> remapPendingTaskId({
    required int localId,
    required int serverId,
  }) async {
    if (localId == serverId) return;
    try {
      final pending = await getPendingOperations();
      for (final operation in pending) {
        if (operation.taskId != localId) continue;
        // Create for this local id should already be removed; skip if still present.
        if (operation.operationType == PendingOperationType.create) continue;

        final payload = Map<String, dynamic>.from(operation.payload);
        if (payload['id'] == localId) {
          payload['id'] = serverId;
        }
        await updatePendingOperation(
          operation.copyWith(taskId: serverId, payload: payload),
        );
      }
    } catch (error) {
      throw CacheException(message: error.toString());
    }
  }

  @override
  Future<void> enqueuePendingOperation(PendingSyncModel operation) async {
    try {
      await _hiveService.pendingOperationsBox.put(
        operation.operationId,
        operation,
      );
    } catch (error) {
      throw CacheException(message: error.toString());
    }
  }

  @override
  Future<List<PendingSyncModel>> getPendingOperations() async {
    try {
      final values = _hiveService.pendingOperationsBox.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return values;
    } catch (error) {
      throw CacheException(message: error.toString());
    }
  }

  @override
  Future<void> removePendingOperation(String operationId) async {
    try {
      await _hiveService.pendingOperationsBox.delete(operationId);
    } catch (error) {
      throw CacheException(message: error.toString());
    }
  }

  @override
  Future<void> updatePendingOperation(PendingSyncModel operation) async {
    try {
      await _hiveService.pendingOperationsBox.put(
        operation.operationId,
        operation,
      );
    } catch (error) {
      throw CacheException(message: error.toString());
    }
  }

  @override
  Future<bool> hasPendingOperationsForTask(int taskId) async {
    final pending = await getPendingOperations();
    return pending.any((operation) => operation.taskId == taskId);
  }

  @override
  Future<Set<int>> getPendingTaskIds() async {
    final pending = await getPendingOperations();
    return pending.map((operation) => operation.taskId).toSet();
  }

  @override
  Future<void> clearAllTaskCache() async {
    try {
      await _hiveService.taskListBox.clear();
      await _hiveService.taskDetailsBox.clear();
      await _hiveService.tasksBox.clear();
      await _hiveService.pendingOperationsBox.clear();
      MockTaskInterceptor.active?.reset();
    } catch (error) {
      throw CacheException(message: error.toString());
    }
  }
}
