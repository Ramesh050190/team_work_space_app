import 'package:dartz/dartz.dart';
import 'package:team_workspace/core/errors/failure.dart';
import 'package:team_workspace/features/dashboard/domain/entities/paginated_tasks_page.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';

/// Contract for dashboard task listing (remote + Hive cache).
abstract class DashboardRepository {
  /// Fetches tasks with offline-first strategy.
  Future<Either<Failure, PaginatedTasksPage>> getTasks({
    required int page,
    required int limit,
    bool cacheOnly = false,
    String searchQuery = '',
    TaskStatus? status,
    TaskPriority? priority,
  });
}
