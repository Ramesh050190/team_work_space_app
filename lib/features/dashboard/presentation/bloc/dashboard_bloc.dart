import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:team_workspace/core/constants/api_constants.dart';
import 'package:team_workspace/features/dashboard/domain/entities/paginated_tasks_page.dart';
import 'package:team_workspace/features/dashboard/domain/entities/task_entity.dart';
import 'package:team_workspace/features/dashboard/domain/usecases/get_tasks_usecase.dart';
import 'package:team_workspace/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:team_workspace/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';

/// Handles paginated loading with offline-first paint, search, and filters.
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({required GetTasksUseCase getTasksUseCase})
    : _getTasksUseCase = getTasksUseCase,
      super(const DashboardInitial()) {
    on<LoadTasks>(_onLoadTasks);
    on<LoadMoreTasks>(_onLoadMoreTasks);
    on<RefreshTasks>(_onRefreshTasks);
    on<SearchTasksChanged>(_onSearchTasksChanged);
    on<ApplyTaskFilters>(_onApplyTaskFilters);
    on<ResetDashboard>(_onResetDashboard);
  }

  final GetTasksUseCase _getTasksUseCase;

  static const int _pageSize = ApiConstants.defaultPageSize;

  bool _isFetching = false;
  String _searchQuery = '';
  TaskStatus? _statusFilter;
  TaskPriority? _priorityFilter;

  void _onResetDashboard(ResetDashboard event, Emitter<DashboardState> emit) {
    _isFetching = false;
    _searchQuery = '';
    _statusFilter = null;
    _priorityFilter = null;
    emit(const DashboardInitial());
  }

  GetTasksParams _params({required int page, bool cacheOnly = false}) {
    return GetTasksParams(
      page: page,
      limit: _pageSize,
      cacheOnly: cacheOnly,
      searchQuery: _searchQuery,
      status: _statusFilter,
      priority: _priorityFilter,
    );
  }

  Future<void> _onSearchTasksChanged(
    SearchTasksChanged event,
    Emitter<DashboardState> emit,
  ) async {
    final next = event.query.trim();
    if (next == _searchQuery) return;
    _searchQuery = next;
    await _reloadFirstPage(emit, showLoadingIfEmpty: true);
  }

  Future<void> _onApplyTaskFilters(
    ApplyTaskFilters event,
    Emitter<DashboardState> emit,
  ) async {
    _statusFilter = event.status;
    _priorityFilter = event.priority;
    await _reloadFirstPage(emit, showLoadingIfEmpty: true);
  }

  Future<void> _onLoadTasks(
    LoadTasks event,
    Emitter<DashboardState> emit,
  ) async {
    if (_isFetching) return;
    _isFetching = true;

    final cached = await _getTasksUseCase(_params(page: 1, cacheOnly: true));
    final hasCache = cached.fold((_) => false, (page) => page.tasks.isNotEmpty);
    cached.fold((_) {}, (page) {
      if (page.tasks.isNotEmpty) {
        emit(_loadedFromPage(page, isFromCache: true));
      }
    });

    if (!hasCache) {
      emit(_loadingState());
    }

    final result = await _getTasksUseCase(_params(page: 1));
    _isFetching = false;

    result.fold((failure) {
      if (state is DashboardLoaded) {
        final loaded = state as DashboardLoaded;
        emit(loaded.copyWith(isFromCache: true));
        return;
      }
      emit(
        DashboardError(
          message: failure.message,
          searchQuery: _searchQuery,
          statusFilter: _statusFilter,
          priorityFilter: _priorityFilter,
        ),
      );
    }, (page) => emit(_loadedFromPage(page)));
  }

  Future<void> _onLoadMoreTasks(
    LoadMoreTasks event,
    Emitter<DashboardState> emit,
  ) async {
    final current = state;
    if (_isFetching) return;

    final List<TaskEntity> existing;
    final int currentPage;
    final bool hasReachedMax;

    if (current is DashboardLoaded) {
      existing = current.tasks;
      currentPage = current.currentPage;
      hasReachedMax = current.hasReachedMax;
    } else if (current is DashboardLoadingMore) {
      return;
    } else {
      return;
    }

    if (hasReachedMax) return;

    _isFetching = true;
    emit(
      DashboardLoadingMore(
        tasks: existing,
        currentPage: currentPage,
        hasReachedMax: hasReachedMax,
        searchQuery: _searchQuery,
        statusFilter: _statusFilter,
        priorityFilter: _priorityFilter,
      ),
    );

    final nextPage = currentPage + 1;
    final result = await _getTasksUseCase(_params(page: nextPage));
    _isFetching = false;

    result.fold(
      (failure) {
        emit(
          DashboardError(
            message: failure.message,
            tasks: existing,
            currentPage: currentPage,
            hasReachedMax: hasReachedMax,
            searchQuery: _searchQuery,
            statusFilter: _statusFilter,
            priorityFilter: _priorityFilter,
          ),
        );
      },
      (page) {
        final merged = _mergeUnique(existing, page.tasks);
        emit(
          DashboardLoaded(
            tasks: merged,
            currentPage: page.page,
            hasReachedMax: page.page >= page.totalPages || page.tasks.isEmpty,
            searchQuery: _searchQuery,
            statusFilter: _statusFilter,
            priorityFilter: _priorityFilter,
          ),
        );
      },
    );
  }

  Future<void> _onRefreshTasks(
    RefreshTasks event,
    Emitter<DashboardState> emit,
  ) async {
    await _reloadFirstPage(emit, showLoadingIfEmpty: true);
  }

  Future<void> _reloadFirstPage(
    Emitter<DashboardState> emit, {
    required bool showLoadingIfEmpty,
  }) async {
    if (_isFetching) return;
    _isFetching = true;

    final previousTasks = switch (state) {
      DashboardLoaded(:final tasks) => tasks,
      DashboardLoadingMore(:final tasks) => tasks,
      DashboardError(:final tasks) => tasks,
      _ => const <TaskEntity>[],
    };

    if (showLoadingIfEmpty && previousTasks.isEmpty) {
      emit(_loadingState());
    }

    final result = await _getTasksUseCase(_params(page: 1));
    _isFetching = false;

    result.fold((failure) {
      if (previousTasks.isNotEmpty) {
        emit(
          DashboardLoaded(
            tasks: previousTasks,
            currentPage: 1,
            hasReachedMax: false,
            isFromCache: true,
            searchQuery: _searchQuery,
            statusFilter: _statusFilter,
            priorityFilter: _priorityFilter,
          ),
        );
        return;
      }
      emit(
        DashboardError(
          message: failure.message,
          tasks: previousTasks,
          currentPage: 1,
          hasReachedMax: false,
          searchQuery: _searchQuery,
          statusFilter: _statusFilter,
          priorityFilter: _priorityFilter,
        ),
      );
    }, (page) => emit(_loadedFromPage(page)));
  }

  DashboardLoading _loadingState() {
    return DashboardLoading(
      searchQuery: _searchQuery,
      statusFilter: _statusFilter,
      priorityFilter: _priorityFilter,
    );
  }

  DashboardLoaded _loadedFromPage(
    PaginatedTasksPage page, {
    bool isFromCache = false,
  }) {
    return DashboardLoaded(
      tasks: page.tasks,
      currentPage: page.page,
      hasReachedMax: page.page >= page.totalPages,
      isFromCache: isFromCache,
      searchQuery: _searchQuery,
      statusFilter: _statusFilter,
      priorityFilter: _priorityFilter,
    );
  }

  List<TaskEntity> _mergeUnique(
    List<TaskEntity> existing,
    List<TaskEntity> incoming,
  ) {
    final seen = <String>{};
    final merged = <TaskEntity>[];
    for (final task in [...existing, ...incoming]) {
      if (seen.add(task.id)) {
        merged.add(task);
      }
    }
    return merged;
  }
}
