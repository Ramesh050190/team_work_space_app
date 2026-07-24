import 'package:team_workspace/core/exceptions/cache_exception.dart';
import 'package:team_workspace/features/dashboard/data/datasources/dashboard_local_datasource.dart';
import 'package:team_workspace/features/dashboard/data/models/task_model.dart'
    as dashboard;
import 'package:team_workspace/features/dashboard/domain/entities/paginated_tasks_page.dart';
import 'package:team_workspace/features/dashboard/domain/entities/task_entity.dart';
import 'package:team_workspace/features/task/data/datasources/task_local_datasource.dart';
import 'package:team_workspace/features/task/data/models/task_model.dart';
import 'package:team_workspace/features/task/domain/entities/assigned_user.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';

/// Hive-backed dashboard cache that reuses [TaskLocalDataSource] storage.
class DashboardLocalDataSourceImpl implements DashboardLocalDataSource {
  DashboardLocalDataSourceImpl({
    required TaskLocalDataSource taskLocalDataSource,
  }) : _taskLocalDataSource = taskLocalDataSource;

  final TaskLocalDataSource _taskLocalDataSource;

  static const AssignedUser _fallbackAssignee = AssignedUser(
    id: 'u1',
    name: 'Alex Morgan',
    email: 'alex@example.com',
  );

  @override
  Future<PaginatedTasksPage> getCachedTasks({
    required int page,
    required int limit,
    String searchQuery = '',
    TaskStatus? status,
    TaskPriority? priority,
  }) async {
    try {
      final cached = await _taskLocalDataSource.getCachedTaskList();
      var entities = cached.map(_toEntity).toList(growable: false);

      final normalizedSearch = searchQuery.trim().toLowerCase();
      if (normalizedSearch.isNotEmpty) {
        entities = entities
            .where(
              (task) => task.title.toLowerCase().contains(normalizedSearch),
            )
            .toList(growable: false);
      }
      if (status != null) {
        final statusKey = _statusKey(status);
        entities = entities
            .where((task) => _normalizeStatus(task.status) == statusKey)
            .toList(growable: false);
      }
      if (priority != null) {
        entities = entities
            .where(
              (task) =>
                  task.priority.toLowerCase() == priority.name.toLowerCase(),
            )
            .toList(growable: false);
      }

      final totalPages = limit <= 0
          ? 1
          : ((entities.length + limit - 1) ~/ limit).clamp(1, 1 << 30);
      final start = ((page - 1) * limit).clamp(0, entities.length);
      final end = (start + limit).clamp(0, entities.length);
      final slice = entities.sublist(start, end);

      return PaginatedTasksPage(
        tasks: slice,
        page: page,
        totalPages: entities.isEmpty ? 1 : totalPages,
      );
    } on CacheException {
      rethrow;
    } catch (error) {
      throw CacheException(message: 'Failed to read cached tasks: $error');
    }
  }

  @override
  Future<void> cacheTasks(
    List<dashboard.TaskModel> tasks, {
    required int page,
  }) async {
    try {
      final models = tasks.map(_toTaskModel).toList(growable: false);

      if (page <= 1) {
        final existing = await _taskLocalDataSource.getCachedTaskList();
        final byId = <int, TaskModel>{
          for (final task in existing) task.id: task,
        };

        for (final incoming in models) {
          final current = byId[incoming.id];
          if (current != null &&
              current.updatedAt.isAfter(incoming.updatedAt)) {
            continue;
          }
          byId[incoming.id] = incoming;
          await _taskLocalDataSource.cacheTaskDetails(incoming);
        }

        await _taskLocalDataSource.cacheTaskList(
          byId.values.toList(growable: false),
        );
        return;
      }

      for (final model in models) {
        await _taskLocalDataSource.upsertCachedTask(model);
        await _taskLocalDataSource.cacheTaskDetails(model);
      }
    } on CacheException {
      rethrow;
    } catch (error) {
      throw CacheException(message: 'Failed to cache tasks: $error');
    }
  }

  TaskEntity _toEntity(TaskModel model) {
    return TaskEntity(
      id: '${model.id}',
      title: model.title,
      description: model.description,
      status: _statusKey(model.status),
      priority: model.priority.name,
      createdAt: model.createdAt,
    );
  }

  TaskModel _toTaskModel(dashboard.TaskModel model) {
    final id = int.tryParse(model.id) ?? 0;
    final status = TaskStatus.fromString(model.status);
    final priority = TaskPriority.fromString(model.priority);
    final now = DateTime.now().toUtc();

    return TaskModel(
      id: id,
      title: model.title,
      description: model.description,
      priority: priority,
      status: status,
      dueDate: model.createdAt.isAfter(DateTime.fromMillisecondsSinceEpoch(0))
          ? model.createdAt.add(const Duration(days: 7))
          : now.add(const Duration(days: 7)),
      assignedUser: _fallbackAssignee,
      createdAt: model.createdAt,
      updatedAt: now,
      completed: status == TaskStatus.completed,
    );
  }

  String _statusKey(TaskStatus status) {
    return status == TaskStatus.inProgress ? 'in_progress' : status.name;
  }

  String _normalizeStatus(String status) {
    return status.toLowerCase().replaceAll(' ', '_');
  }
}
