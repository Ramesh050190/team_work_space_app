import 'package:team_workspace/features/dashboard/data/models/task_model.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';

/// Remote contract for dashboard task APIs.
abstract class DashboardRemoteDataSource {
  /// GET /tasks?page=&limit=&q=&status=&priority=
  Future<DashboardTasksResponse> getTasks({
    required int page,
    required int limit,
    String searchQuery = '',
    TaskStatus? status,
    TaskPriority? priority,
  });
}

class DashboardTasksResponse {
  const DashboardTasksResponse({
    required this.tasks,
    required this.page,
    required this.totalPages,
  });

  final List<TaskModel> tasks;
  final int page;
  final int totalPages;
}
