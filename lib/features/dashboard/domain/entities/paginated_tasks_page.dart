import 'package:equatable/equatable.dart';
import 'package:team_workspace/features/dashboard/domain/entities/task_entity.dart';

/// Paginated result returned by [DashboardRepository.getTasks].
class PaginatedTasksPage extends Equatable {
  const PaginatedTasksPage({
    required this.tasks,
    required this.page,
    required this.totalPages,
  });

  final List<TaskEntity> tasks;
  final int page;
  final int totalPages;

  bool get hasReachedMax => page >= totalPages || tasks.isEmpty && page > 1;

  @override
  List<Object?> get props => [tasks, page, totalPages];
}
