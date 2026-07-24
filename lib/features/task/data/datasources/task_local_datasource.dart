import 'package:team_workspace/features/task/data/models/pending_sync_model.dart';
import 'package:team_workspace/features/task/data/models/task_model.dart';

abstract class TaskLocalDataSource {
  Future<void> cacheTaskDetails(TaskModel task);

  Future<TaskModel?> getCachedTaskDetails(int id);

  Future<void> clearTaskDetails(int id);

  Future<void> cacheTaskList(List<TaskModel> tasks);

  Future<List<TaskModel>> getCachedTaskList();

  /// Upserts a single task into the cached list (create/update sync).
  Future<void> upsertCachedTask(TaskModel task);

  /// Removes a task from details + list caches.
  Future<void> removeCachedTask(int taskId);

  /// Replaces a locally-generated id with the server id after create sync.
  Future<void> replaceCachedTaskId({
    required int localId,
    required TaskModel serverTask,
  });

  /// Rewrites queued ops that still reference [localId] after a create sync.
  Future<void> remapPendingTaskId({
    required int localId,
    required int serverId,
  });

  Future<void> enqueuePendingOperation(PendingSyncModel operation);

  Future<List<PendingSyncModel>> getPendingOperations();

  Future<void> removePendingOperation(String operationId);

  Future<void> updatePendingOperation(PendingSyncModel operation);

  Future<bool> hasPendingOperationsForTask(int taskId);

  Future<Set<int>> getPendingTaskIds();

  /// Clears task list, details, typed task box, and pending sync outbox.
  Future<void> clearAllTaskCache();
}
