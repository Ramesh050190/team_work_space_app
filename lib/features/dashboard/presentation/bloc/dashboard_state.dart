import 'package:equatable/equatable.dart';
import 'package:team_workspace/features/dashboard/domain/entities/task_entity.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';

/// Dashboard UI states.
sealed class DashboardState extends Equatable {
  const DashboardState();

  String get searchQuery => '';
  TaskStatus? get statusFilter => null;
  TaskPriority? get priorityFilter => null;

  bool get hasActiveFilters => statusFilter != null || priorityFilter != null;
  bool get hasActiveSearch => searchQuery.trim().isNotEmpty;
  bool get hasActiveQuery => hasActiveFilters || hasActiveSearch;

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

/// Full-screen loading for the first page (no cache available yet).
class DashboardLoading extends DashboardState {
  const DashboardLoading({
    this.searchQuery = '',
    this.statusFilter,
    this.priorityFilter,
  });

  @override
  final String searchQuery;
  @override
  final TaskStatus? statusFilter;
  @override
  final TaskPriority? priorityFilter;

  @override
  List<Object?> get props => [searchQuery, statusFilter, priorityFilter];
}

/// Successfully loaded (or refreshed) task list.
class DashboardLoaded extends DashboardState {
  const DashboardLoaded({
    required this.tasks,
    required this.hasReachedMax,
    required this.currentPage,
    this.isFromCache = false,
    this.searchQuery = '',
    this.statusFilter,
    this.priorityFilter,
  });

  final List<TaskEntity> tasks;
  final bool hasReachedMax;
  final int currentPage;
  final bool isFromCache;

  @override
  final String searchQuery;
  @override
  final TaskStatus? statusFilter;
  @override
  final TaskPriority? priorityFilter;

  DashboardLoaded copyWith({
    List<TaskEntity>? tasks,
    bool? hasReachedMax,
    int? currentPage,
    bool? isFromCache,
    String? searchQuery,
    TaskStatus? statusFilter,
    TaskPriority? priorityFilter,
    bool clearStatusFilter = false,
    bool clearPriorityFilter = false,
  }) {
    return DashboardLoaded(
      tasks: tasks ?? this.tasks,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      isFromCache: isFromCache ?? this.isFromCache,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatusFilter
          ? null
          : statusFilter ?? this.statusFilter,
      priorityFilter: clearPriorityFilter
          ? null
          : priorityFilter ?? this.priorityFilter,
    );
  }

  @override
  List<Object?> get props => [
    tasks,
    hasReachedMax,
    currentPage,
    isFromCache,
    searchQuery,
    statusFilter,
    priorityFilter,
  ];
}

/// Append-in-progress while keeping the current list visible.
class DashboardLoadingMore extends DashboardState {
  const DashboardLoadingMore({
    required this.tasks,
    required this.hasReachedMax,
    required this.currentPage,
    this.searchQuery = '',
    this.statusFilter,
    this.priorityFilter,
  });

  final List<TaskEntity> tasks;
  final bool hasReachedMax;
  final int currentPage;

  @override
  final String searchQuery;
  @override
  final TaskStatus? statusFilter;
  @override
  final TaskPriority? priorityFilter;

  @override
  List<Object?> get props => [
    tasks,
    hasReachedMax,
    currentPage,
    searchQuery,
    statusFilter,
    priorityFilter,
  ];
}

/// Failure state with optional previously loaded tasks for soft recovery.
class DashboardError extends DashboardState {
  const DashboardError({
    required this.message,
    this.tasks = const [],
    this.currentPage = 1,
    this.hasReachedMax = false,
    this.searchQuery = '',
    this.statusFilter,
    this.priorityFilter,
  });

  final String message;
  final List<TaskEntity> tasks;
  final int currentPage;
  final bool hasReachedMax;

  @override
  final String searchQuery;
  @override
  final TaskStatus? statusFilter;
  @override
  final TaskPriority? priorityFilter;

  @override
  List<Object?> get props => [
    message,
    tasks,
    currentPage,
    hasReachedMax,
    searchQuery,
    statusFilter,
    priorityFilter,
  ];
}
