import 'package:dartz/dartz.dart' hide Task;
import 'package:team_workspace/core/errors/failure.dart';
import 'package:team_workspace/features/dashboard/domain/entities/paginated_tasks.dart';
import 'package:team_workspace/features/dashboard/domain/entities/task_query.dart';
import 'package:team_workspace/features/task/domain/entities/task.dart';

abstract class TaskRepository {
  Future<Either<Failure, Task>> getTaskDetails(int id);

  Future<Either<Failure, Task>> updateTaskStatus({
    required int id,
    required bool completed,
  });

  Future<Either<Failure, Task>> createTask(Task task);

  Future<Either<Failure, Task>> updateTask(Task task);

  Future<Either<Failure, PaginatedTasks>> searchTasks(TaskQuery query);

  Future<Either<Failure, PaginatedTasks>> filterTasks(TaskQuery query);
}
