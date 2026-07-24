import 'package:equatable/equatable.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';

/// Dashboard UI events.
sealed class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

/// Initial load (page 1) with full-screen loader.
class LoadTasks extends DashboardEvent {
  const LoadTasks();
}

/// Clears in-memory list/filters after logout or account switch.
class ResetDashboard extends DashboardEvent {
  const ResetDashboard();
}

/// Load the next page when the user scrolls near the bottom.
class LoadMoreTasks extends DashboardEvent {
  const LoadMoreTasks();
}

/// Pull-to-refresh: reload from page 1.
class RefreshTasks extends DashboardEvent {
  const RefreshTasks();
}

/// Debounced title search (works together with status/priority filters).
class SearchTasksChanged extends DashboardEvent {
  const SearchTasksChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

/// Apply status / priority filters and reload page 1 (keeps current search).
class ApplyTaskFilters extends DashboardEvent {
  const ApplyTaskFilters({this.status, this.priority});

  final TaskStatus? status;
  final TaskPriority? priority;

  @override
  List<Object?> get props => [status, priority];
}
