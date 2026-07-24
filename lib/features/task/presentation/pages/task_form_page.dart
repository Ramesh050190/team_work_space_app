import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:team_workspace/core/constants/app_strings.dart';
import 'package:team_workspace/core/di/app_di.dart';
import 'package:team_workspace/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:team_workspace/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:team_workspace/features/task/domain/usecases/get_task_details_usecase.dart';
import 'package:team_workspace/features/task/presentation/bloc/sync/sync_bloc.dart';
import 'package:team_workspace/features/task/presentation/bloc/task_form/task_form_bloc.dart';
import 'package:team_workspace/features/task/presentation/bloc/task_form/task_form_event.dart';
import 'package:team_workspace/features/task/presentation/bloc/task_form/task_form_state.dart';
import 'package:team_workspace/features/task/presentation/widgets/task_form.dart';

class TaskFormPage extends StatelessWidget {
  const TaskFormPage.create({super.key})
    : mode = TaskFormMode.create,
      taskId = null;

  const TaskFormPage.edit({super.key, required this.taskId})
    : mode = TaskFormMode.edit;

  final TaskFormMode mode;
  final int? taskId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TaskFormBloc>(),
      child: _TaskFormPageBody(mode: mode, taskId: taskId),
    );
  }
}

class _TaskFormPageBody extends StatefulWidget {
  const _TaskFormPageBody({required this.mode, this.taskId});

  final TaskFormMode mode;
  final int? taskId;

  @override
  State<_TaskFormPageBody> createState() => _TaskFormPageBodyState();
}

class _TaskFormPageBodyState extends State<_TaskFormPageBody> {
  bool _loadingExisting = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (widget.mode == TaskFormMode.create) {
      context.read<TaskFormBloc>().add(
        const InitializeForm(mode: TaskFormMode.create),
      );
      return;
    }

    setState(() {
      _loadingExisting = true;
      _loadError = null;
    });

    final result = await sl<GetTaskDetailsUseCase>()(
      GetTaskDetailsParams(id: widget.taskId!),
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _loadingExisting = false;
          _loadError = failure.message;
        });
      },
      (task) {
        setState(() => _loadingExisting = false);
        context.read<TaskFormBloc>().add(
          InitializeForm(mode: TaskFormMode.edit, existingTask: task),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.mode == TaskFormMode.edit;

    return BlocListener<TaskFormBloc, TaskFormState>(
      listenWhen: (previous, current) =>
          current is TaskFormSuccess ||
          current is TaskFormFailure ||
          (current is TaskFormEditing &&
              current.submitError != null &&
              (previous is! TaskFormEditing ||
                  previous.submitError != current.submitError)),
      listener: (context, state) {
        if (state is TaskFormSuccess) {
          final dashboard = context.read<DashboardBloc>();
          dashboard.add(const RefreshTasks());

          context.read<SyncBloc>().refreshPending();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.of(context).resolveMessage(state.message),
              ),
            ),
          );
          context.pop(state.task);
          return;
        }

        if (state is TaskFormFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.of(context).resolveMessage(state.message),
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }

        if (state is TaskFormEditing && state.submitError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.of(context).resolveMessage(state.submitError),
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          context.read<TaskFormBloc>().add(const ClearFormMessage());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isEdit
                ? AppStrings.of(context).editTask
                : AppStrings.of(context).createTask,
          ),
        ),
        body: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (_loadingExisting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _bootstrap,
                child: Text(AppStrings.of(context).retry),
              ),
            ],
          ),
        ),
      );
    }

    return const TaskForm();
  }
}
