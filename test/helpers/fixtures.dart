import 'package:team_workspace/features/authentication/domain/entities/app_user.dart';
import 'package:team_workspace/features/dashboard/domain/entities/paginated_tasks.dart';
import 'package:team_workspace/features/task/domain/entities/assigned_user.dart';
import 'package:team_workspace/features/task/domain/entities/task.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';

/// Shared fake domain objects for unit and widget tests.
class FakeData {
  FakeData._();

  static const user = AppUser(
    uid: 'uid-1',
    email: 'test@example.com',
    displayName: 'Test User',
  );

  static const assignedUser = AssignedUser(
    id: 'u1',
    name: 'Alex Morgan',
    email: 'alex@example.com',
  );

  static final dueDate = DateTime.utc(2026, 7, 25);
  static final createdAt = DateTime.utc(2026, 7, 20, 8);
  static final updatedAt = DateTime.utc(2026, 7, 20, 8);

  static Task task({
    int id = 1,
    String title = 'Flutter Task',
    String description = 'Testing task description',
    TaskPriority priority = TaskPriority.medium,
    TaskStatus status = TaskStatus.pending,
    bool completed = false,
  }) {
    return Task(
      id: id,
      title: title,
      description: description,
      priority: priority,
      status: status,
      dueDate: dueDate,
      assignedUser: assignedUser,
      createdAt: createdAt,
      updatedAt: updatedAt,
      completed: completed,
    );
  }

  static PaginatedTasks paginatedTasks({
    List<Task>? tasks,
    int page = 1,
    int limit = 10,
    int? total,
    bool? hasMore,
  }) {
    final list = tasks ?? [task()];
    return PaginatedTasks(
      tasks: list,
      page: page,
      limit: limit,
      total: total ?? list.length,
      hasMore: hasMore ?? false,
    );
  }
}
