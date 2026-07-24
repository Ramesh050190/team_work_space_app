import 'package:equatable/equatable.dart';
import 'package:team_workspace/features/task/domain/entities/task.dart';

class PaginatedTasks extends Equatable {
  const PaginatedTasks({
    required this.tasks,
    required this.page,
    required this.limit,
    required this.total,
    required this.hasMore,
  });

  final List<Task> tasks;
  final int page;
  final int limit;
  final int total;
  final bool hasMore;

  @override
  List<Object?> get props => [tasks, page, limit, total, hasMore];
}
