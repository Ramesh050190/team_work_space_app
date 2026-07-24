import 'package:team_workspace/features/dashboard/data/models/task_model.dart';
import 'package:team_workspace/features/dashboard/domain/entities/paginated_tasks_page.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';

/// Local cache contract for the dashboard task list (Hive-backed).
abstract class DashboardLocalDataSource {
  /// Returns a paginated slice of cached dashboard tasks.
  Future<PaginatedTasksPage> getCachedTasks({
    required int page,
    required int limit,
    String searchQuery = '',
    TaskStatus? status,
    TaskPriority? priority,
  });

  /// Persists tasks from a successful remote page.
  Future<void> cacheTasks(List<TaskModel> tasks, {required int page});
}
