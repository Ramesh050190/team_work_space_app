import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:team_workspace/core/constants/message_keys.dart';
import 'package:team_workspace/features/task/data/datasources/task_local_datasource.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';
import 'package:team_workspace/features/task/domain/usecases/get_task_details_usecase.dart';
import 'package:team_workspace/features/task/domain/usecases/update_task_status_usecase.dart';
import 'package:team_workspace/features/task/presentation/bloc/task_details_event.dart';
import 'package:team_workspace/features/task/presentation/bloc/task_details_state.dart';

class TaskDetailsBloc extends Bloc<TaskDetailsEvent, TaskDetailsState> {
  TaskDetailsBloc({
    required GetTaskDetailsUseCase getTaskDetailsUseCase,
    required UpdateTaskStatusUseCase updateTaskStatusUseCase,
    required int taskId,
    required TaskLocalDataSource taskLocalDataSource,
  }) : _getTaskDetailsUseCase = getTaskDetailsUseCase,
       _updateTaskStatusUseCase = updateTaskStatusUseCase,
       _taskId = taskId,
       _taskLocalDataSource = taskLocalDataSource,
       super(const TaskDetailsInitial()) {
    on<LoadTaskDetails>(_onLoadTaskDetails);
    on<RefreshTaskDetails>(_onRefreshTaskDetails);
    on<MarkCompleted>(_onMarkCompleted);
    on<ReopenTask>(_onReopenTask);
    on<RetryLoading>(_onRetryLoading);
    on<ClearStatusUpdateMessage>(_onClearStatusUpdateMessage);
    on<TaskDetailsContentUpdated>(_onContentUpdated);
  }

  final GetTaskDetailsUseCase _getTaskDetailsUseCase;
  final UpdateTaskStatusUseCase _updateTaskStatusUseCase;
  final TaskLocalDataSource _taskLocalDataSource;
  final int _taskId;

  Future<void> _onLoadTaskDetails(
    LoadTaskDetails event,
    Emitter<TaskDetailsState> emit,
  ) async {
    await _emitCachedFirst(emit);
    await _fetchTaskDetails(emit, showLoading: state is! TaskDetailsLoaded);
  }

  Future<void> _onRefreshTaskDetails(
    RefreshTaskDetails event,
    Emitter<TaskDetailsState> emit,
  ) async {
    await _fetchTaskDetails(emit, showLoading: false);
  }

  Future<void> _onRetryLoading(
    RetryLoading event,
    Emitter<TaskDetailsState> emit,
  ) async {
    emit(const TaskDetailsLoading());
    await _fetchTaskDetails(emit);
  }

  Future<void> _emitCachedFirst(Emitter<TaskDetailsState> emit) async {
    try {
      final cached = await _taskLocalDataSource.getCachedTaskDetails(_taskId);
      if (cached != null) {
        final pending = await _taskLocalDataSource.hasPendingOperationsForTask(
          _taskId,
        );
        emit(
          TaskDetailsLoaded(
            task: cached.toEntity(),
            statusUpdateMessage: pending ? MessageKeys.waitingForSync : null,
          ),
        );
      } else {
        emit(const TaskDetailsLoading());
      }
    } catch (_) {
      emit(const TaskDetailsLoading());
    }
  }

  Future<void> _fetchTaskDetails(
    Emitter<TaskDetailsState> emit, {
    bool showLoading = true,
  }) async {
    if (showLoading && state is! TaskDetailsLoaded) {
      emit(const TaskDetailsLoading());
    }

    final result = await _getTaskDetailsUseCase(
      GetTaskDetailsParams(id: _taskId),
    );

    final pending = await _taskLocalDataSource.hasPendingOperationsForTask(
      _taskId,
    );

    result.fold(
      (failure) {
        if (state is TaskDetailsLoaded) {
          return;
        }
        if (failure.message.toLowerCase().contains('not found')) {
          emit(const TaskDetailsEmpty(message: MessageKeys.taskNotFound));
          return;
        }

        emit(
          TaskDetailsFailure(
            message: failure.message,
            cachedTask: state is TaskDetailsLoaded
                ? (state as TaskDetailsLoaded).task
                : null,
          ),
        );
      },
      (task) => emit(
        TaskDetailsLoaded(
          task: task,
          statusUpdateMessage: pending ? MessageKeys.waitingForSync : null,
        ),
      ),
    );
  }

  Future<void> _onMarkCompleted(
    MarkCompleted event,
    Emitter<TaskDetailsState> emit,
  ) async {
    await _updateStatus(
      emit: emit,
      completed: true,
      successMessage: MessageKeys.taskMarkedCompleted,
    );
  }

  Future<void> _onReopenTask(
    ReopenTask event,
    Emitter<TaskDetailsState> emit,
  ) async {
    await _updateStatus(
      emit: emit,
      completed: false,
      successMessage: MessageKeys.taskReopened,
    );
  }

  Future<void> _updateStatus({
    required Emitter<TaskDetailsState> emit,
    required bool completed,
    required String successMessage,
  }) async {
    final currentState = state;
    if (currentState is! TaskDetailsLoaded) return;

    final previousTask = currentState.task;
    final optimisticTask = previousTask.copyWith(
      completed: completed,
      status: completed ? TaskStatus.completed : TaskStatus.pending,
      updatedAt: DateTime.now().toUtc(),
    );

    emit(TaskDetailsUpdating(task: optimisticTask, previousTask: previousTask));

    final result = await _updateTaskStatusUseCase(
      UpdateTaskStatusParams(id: _taskId, completed: completed),
    );

    final pending = await _taskLocalDataSource.hasPendingOperationsForTask(
      _taskId,
    );

    result.fold(
      (failure) {
        emit(
          TaskDetailsLoaded(
            task: previousTask,
            statusUpdateMessage: failure.message,
          ),
        );
      },
      (task) {
        emit(
          TaskDetailsSuccess(
            task: task,
            message: pending
                ? MessageKeys.savedOfflineWaitingSync
                : successMessage,
          ),
        );
        emit(
          TaskDetailsLoaded(
            task: task,
            statusUpdateMessage: pending ? MessageKeys.waitingForSync : null,
          ),
        );
      },
    );
  }

  void _onClearStatusUpdateMessage(
    ClearStatusUpdateMessage event,
    Emitter<TaskDetailsState> emit,
  ) {
    final currentState = state;
    if (currentState is TaskDetailsLoaded) {
      emit(currentState.copyWith(clearStatusUpdateMessage: true));
    }
  }

  void _onContentUpdated(
    TaskDetailsContentUpdated event,
    Emitter<TaskDetailsState> emit,
  ) {
    if (event.task.id != _taskId) return;
    emit(TaskDetailsLoaded(task: event.task));
  }
}
