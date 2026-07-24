import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:team_workspace/core/constants/app_strings.dart';
import 'package:team_workspace/core/constants/route_constants.dart';
import 'package:team_workspace/core/di/app_di.dart';
import 'package:team_workspace/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:team_workspace/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:team_workspace/features/task/domain/entities/task.dart';
import 'package:team_workspace/features/task/presentation/bloc/task_details_bloc.dart';
import 'package:team_workspace/features/task/presentation/bloc/task_details_event.dart';
import 'package:team_workspace/features/task/presentation/bloc/task_details_state.dart';
import 'package:team_workspace/features/task/presentation/widgets/loading_placeholder.dart';
import 'package:team_workspace/features/task/presentation/widgets/task_info_card.dart';

class TaskDetailsPage extends StatelessWidget {
  const TaskDetailsPage({super.key, required this.taskId});

  final int taskId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<TaskDetailsBloc>(param1: taskId)..add(LoadTaskDetails(taskId)),
      child: const _TaskDetailsView(),
    );
  }
}

class _TaskDetailsView extends StatelessWidget {
  const _TaskDetailsView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TaskDetailsBloc, TaskDetailsState>(
      listenWhen: (previous, current) =>
          current is TaskDetailsSuccess ||
          (current is TaskDetailsLoaded &&
              current.statusUpdateMessage != null &&
              (previous is! TaskDetailsLoaded ||
                  previous.statusUpdateMessage != current.statusUpdateMessage)),
      listener: (context, state) {
        if (state is TaskDetailsSuccess) {
          context.read<DashboardBloc>().add(const RefreshTasks());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.of(context).resolveMessage(state.message),
              ),
            ),
          );
        }

        if (state is TaskDetailsLoaded && state.statusUpdateMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.of(
                  context,
                ).resolveMessage(state.statusUpdateMessage),
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          context.read<TaskDetailsBloc>().add(const ClearStatusUpdateMessage());
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_appBarTitle(context, state)),
            actions: [
              if (state is TaskDetailsLoaded ||
                  state is TaskDetailsUpdating ||
                  state is TaskDetailsSuccess)
                IconButton(
                  tooltip: AppStrings.of(context).editTaskTooltip,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _openEdit(context, state),
                ),
            ],
          ),
          body: SafeArea(child: _TaskDetailsBody(state: state)),
        );
      },
    );
  }

  Future<void> _openEdit(BuildContext context, TaskDetailsState state) async {
    final task = switch (state) {
      TaskDetailsLoaded(:final task) => task,
      TaskDetailsUpdating(:final task) => task,
      TaskDetailsSuccess(:final task) => task,
      _ => null,
    };
    if (task == null) return;

    final result = await context.push<Task>(
      RouteConstants.editTaskPath(task.id),
    );

    if (!context.mounted || result == null) return;

    context.read<TaskDetailsBloc>().add(TaskDetailsContentUpdated(result));
    context.read<DashboardBloc>().add(const RefreshTasks());
  }

  String _appBarTitle(BuildContext context, TaskDetailsState state) {
    if (state is TaskDetailsLoaded) return state.task.title;
    if (state is TaskDetailsUpdating) return state.task.title;
    if (state is TaskDetailsSuccess) return state.task.title;
    return AppStrings.of(context).taskDetails;
  }
}

class _TaskDetailsBody extends StatelessWidget {
  const _TaskDetailsBody({required this.state});

  final TaskDetailsState state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      TaskDetailsInitial() ||
      TaskDetailsLoading() => const LoadingPlaceholder(),
      TaskDetailsFailure(:final message, :final cachedTask) => _FailureView(
        message: message,
        cachedTask: cachedTask,
      ),
      TaskDetailsEmpty(:final message) => _EmptyView(message: message),
      TaskDetailsLoaded(:final task) => _LoadedView(
        task: task,
        isUpdating: false,
      ),
      TaskDetailsUpdating(:final task) => _LoadedView(
        task: task,
        isUpdating: true,
      ),
      TaskDetailsSuccess(:final task) => _LoadedView(
        task: task,
        isUpdating: false,
      ),
    };
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({required this.task, required this.isUpdating});

  final Task task;
  final bool isUpdating;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<TaskDetailsBloc>().add(RefreshTaskDetails(task.id));
        await context.read<TaskDetailsBloc>().stream.firstWhere(
          (state) =>
              state is TaskDetailsLoaded ||
              state is TaskDetailsFailure ||
              state is TaskDetailsEmpty,
        );
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TaskInfoCard(task: task),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          _StatusActionButton(task: task, isUpdating: isUpdating),
        ],
      ),
    );
  }
}

class _StatusActionButton extends StatelessWidget {
  const _StatusActionButton({required this.task, required this.isUpdating});

  final Task task;
  final bool isUpdating;

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.completed;
    final strings = AppStrings.of(context);

    return Semantics(
      button: true,
      enabled: !isUpdating,
      label: isCompleted ? strings.reopenTask : strings.markCompleted,
      child: FilledButton.icon(
        onPressed: isUpdating
            ? null
            : () {
                final bloc = context.read<TaskDetailsBloc>();
                if (isCompleted) {
                  bloc.add(const ReopenTask());
                } else {
                  bloc.add(const MarkCompleted());
                }
              },
        icon: isUpdating
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              )
            : Icon(isCompleted ? Icons.refresh : Icons.check_circle_outline),
        label: Text(isCompleted ? strings.reopenTask : strings.markCompleted),
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message, this.cachedTask});

  final String message;
  final Task? cachedTask;

  @override
  Widget build(BuildContext context) {
    if (cachedTask != null) {
      return _LoadedView(task: cachedTask!, isUpdating: false);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.of(context).resolveMessage(message),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                context.read<TaskDetailsBloc>().add(const RetryLoading());
              },
              child: Text(AppStrings.of(context).retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.of(context).resolveMessage(message),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
