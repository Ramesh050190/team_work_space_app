import 'package:equatable/equatable.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';

/// Immutable query criteria for dashboard search, filters, and pagination.
class TaskQuery extends Equatable {
  const TaskQuery({
    this.searchQuery = '',
    this.status,
    this.priority,
    this.page = 1,
    this.limit = 10,
  });

  final String searchQuery;
  final TaskStatus? status;
  final TaskPriority? priority;
  final int page;
  final int limit;

  bool get hasActiveFilters => status != null || priority != null;

  bool get hasSearch => searchQuery.trim().isNotEmpty;

  TaskQuery copyWith({
    String? searchQuery,
    TaskStatus? status,
    TaskPriority? priority,
    int? page,
    int? limit,
    bool clearStatus = false,
    bool clearPriority = false,
  }) {
    return TaskQuery(
      searchQuery: searchQuery ?? this.searchQuery,
      status: clearStatus ? null : status ?? this.status,
      priority: clearPriority ? null : priority ?? this.priority,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  TaskQuery clearFilters() {
    return TaskQuery(searchQuery: searchQuery, page: 1, limit: limit);
  }

  @override
  List<Object?> get props => [searchQuery, status, priority, page, limit];
}
