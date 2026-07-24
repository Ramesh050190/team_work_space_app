import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:team_workspace/core/constants/app_strings.dart';
import 'package:team_workspace/core/constants/route_constants.dart';
import 'package:team_workspace/features/dashboard/domain/entities/task_entity.dart';
import 'package:team_workspace/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:team_workspace/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:team_workspace/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:team_workspace/features/dashboard/presentation/widgets/pagination_loader.dart';
import 'package:team_workspace/features/dashboard/presentation/widgets/task_card.dart';
import 'package:team_workspace/features/dashboard/presentation/widgets/task_filter_bottom_sheet.dart';
import 'package:team_workspace/features/dashboard/presentation/widgets/task_search_field.dart';
import 'package:team_workspace/features/task/presentation/bloc/sync/sync_bloc.dart';
import 'package:team_workspace/features/task/presentation/bloc/sync/sync_state.dart';
import 'package:team_workspace/features/task/presentation/widgets/sync_status_banner.dart';

/// Paginated task list with pull-to-refresh, infinite scroll, and filters.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // After logout/login, [ResetDashboard] returns this bloc to Initial so a
    // new account never reuses the previous in-memory list.
    final bloc = context.read<DashboardBloc>();
    if (bloc.state is DashboardInitial) {
      bloc.add(const LoadTasks());
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      context.read<DashboardBloc>().add(const LoadMoreTasks());
    }
  }

  Future<void> _onRefresh() async {
    final bloc = context.read<DashboardBloc>();
    bloc.add(const RefreshTasks());
    await bloc.stream.firstWhere(
      (state) => state is DashboardLoaded || state is DashboardError,
    );
  }

  void _openTask(TaskEntity task) {
    final id = int.tryParse(task.id);
    if (id == null) return;
    context.push(RouteConstants.taskDetailsPath(id));
  }

  void _openFilters(DashboardState state) {
    TaskFilterBottomSheet.show(
      context,
      initialStatus: state.statusFilter,
      initialPriority: state.priorityFilter,
      onApply: ({status, priority}) {
        context.read<DashboardBloc>().add(
          ApplyTaskFilters(status: status, priority: priority),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.tasksTitle),
        actions: [
          BlocBuilder<DashboardBloc, DashboardState>(
            buildWhen: (previous, current) =>
                previous.statusFilter != current.statusFilter ||
                previous.priorityFilter != current.priorityFilter,
            builder: (context, state) {
              return IconButton(
                key: const ValueKey('dashboard-filter-button'),
                tooltip: strings.filters,
                onPressed: () {
                  // Always read the latest bloc state — do not close over a
                  // stale builder snapshot when only filter *values* change.
                  final latest = context.read<DashboardBloc>().state;
                  _openFilters(latest);
                },
                icon: Badge(
                  isLabelVisible: state.hasActiveFilters,
                  child: const Icon(Icons.filter_list),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: strings.openProfile,
            onPressed: () => context.push(RouteConstants.profile),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteConstants.createTask),
        icon: const Icon(Icons.add),
        label: Text(strings.createTask),
      ),
      body: Column(
        children: [
          const SyncStatusBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TaskSearchField(
              initialQuery: context.read<DashboardBloc>().state.searchQuery,
              onChanged: (query) {
                context.read<DashboardBloc>().add(SearchTasksChanged(query));
              },
            ),
          ),
          BlocListener<SyncBloc, SyncState>(
            listenWhen: (previous, current) {
              final cameOnline =
                  previous is SyncOffline &&
                  (current is SyncSynced || current is SyncSyncing);
              final syncFinishedClean =
                  previous is SyncSyncing && current is SyncSynced;
              return cameOnline || syncFinishedClean;
            },
            listener: (context, state) {
              context.read<DashboardBloc>().add(const RefreshTasks());
            },
            child: const SizedBox.shrink(),
          ),
          Expanded(
            child: BlocBuilder<DashboardBloc, DashboardState>(
              buildWhen: (previous, current) => previous != current,
              builder: (context, state) {
                return switch (state) {
                  DashboardInitial() || DashboardLoading() => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  DashboardError(:final message, :final tasks) =>
                    tasks.isNotEmpty
                        ? _TaskList(
                            controller: _scrollController,
                            tasks: tasks,
                            showPaginationLoader: false,
                            onRefresh: _onRefresh,
                            onTaskTap: _openTask,
                          )
                        : _ErrorView(
                            message: message,
                            onRetry: () {
                              context.read<DashboardBloc>().add(
                                const LoadTasks(),
                              );
                            },
                          ),
                  DashboardLoaded(:final tasks, :final hasReachedMax) =>
                    tasks.isEmpty
                        ? _EmptyView(
                            onRefresh: _onRefresh,
                            hasQuery: state.hasActiveQuery,
                          )
                        : _TaskList(
                            controller: _scrollController,
                            tasks: tasks,
                            showPaginationLoader: !hasReachedMax,
                            onRefresh: _onRefresh,
                            onTaskTap: _openTask,
                          ),
                  DashboardLoadingMore(:final tasks) => _TaskList(
                    controller: _scrollController,
                    tasks: tasks,
                    showPaginationLoader: true,
                    forceShowLoader: true,
                    onRefresh: _onRefresh,
                    onTaskTap: _openTask,
                  ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList({
    required this.controller,
    required this.tasks,
    required this.showPaginationLoader,
    required this.onRefresh,
    required this.onTaskTap,
    this.forceShowLoader = false,
  });

  final ScrollController controller;
  final List<TaskEntity> tasks;
  final bool showPaginationLoader;
  final bool forceShowLoader;
  final Future<void> Function() onRefresh;
  final ValueChanged<TaskEntity> onTaskTap;

  @override
  Widget build(BuildContext context) {
    final showLoader = forceShowLoader || showPaginationLoader;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: BlocBuilder<SyncBloc, SyncState>(
        buildWhen: (previous, current) =>
            previous.pendingTaskIds != current.pendingTaskIds,
        builder: (context, syncState) {
          return ListView.builder(
            controller: controller,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 88),
            itemCount: tasks.length + (showLoader ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= tasks.length) {
                return const PaginationLoader();
              }
              final task = tasks[index];
              final taskId = int.tryParse(task.id);
              final pending =
                  taskId != null && syncState.pendingTaskIds.contains(taskId);
              return TaskCard(
                task: task,
                isPendingSync: pending,
                onTap: () => onTaskTap(task),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRefresh, this.hasQuery = false});

  final Future<void> Function() onRefresh;
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.5,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  hasQuery
                      ? strings.tryChangingSearchOrFilters
                      : strings.noTasksYet,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: Text(AppStrings.of(context).retry),
            ),
          ],
        ),
      ),
    );
  }
}
