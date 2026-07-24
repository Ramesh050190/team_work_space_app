import 'package:team_workspace/features/dashboard/domain/entities/task_query.dart';
import 'package:team_workspace/features/task/data/models/task_model.dart';

class PaginatedTaskModels {
  const PaginatedTaskModels({
    required this.tasks,
    required this.page,
    required this.limit,
    required this.total,
    required this.hasMore,
  });

  final List<TaskModel> tasks;
  final int page;
  final int limit;
  final int total;
  final bool hasMore;
}

abstract class TaskRemoteDataSource {
  Future<TaskModel> getTaskDetails(int id);

  Future<TaskModel> updateTaskStatus({
    required int id,
    required bool completed,
  });

  Future<TaskModel> createTask(TaskModel task);

  Future<TaskModel> updateTask(TaskModel task);

  Future<PaginatedTaskModels> queryTasks(TaskQuery query);
}
