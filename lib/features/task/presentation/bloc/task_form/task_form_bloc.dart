import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:team_workspace/core/constants/message_keys.dart';
import 'package:team_workspace/features/task/domain/entities/assigned_user.dart';
import 'package:team_workspace/features/task/domain/entities/task.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';
import 'package:team_workspace/features/task/domain/usecases/create_task_usecase.dart';
import 'package:team_workspace/features/task/domain/usecases/update_task_usecase.dart';
import 'package:team_workspace/features/task/domain/validators/task_form_validator.dart';
import 'package:team_workspace/features/task/presentation/bloc/task_form/task_form_event.dart';
import 'package:team_workspace/features/task/presentation/bloc/task_form/task_form_state.dart';

class TaskFormBloc extends Bloc<TaskFormEvent, TaskFormState> {
  TaskFormBloc({
    required CreateTaskUseCase createTaskUseCase,
    required UpdateTaskUseCase updateTaskUseCase,
  }) : _createTaskUseCase = createTaskUseCase,
       _updateTaskUseCase = updateTaskUseCase,
       super(const TaskFormInitial()) {
    on<InitializeForm>(_onInitializeForm);
    on<TitleChanged>(_onTitleChanged);
    on<DescriptionChanged>(_onDescriptionChanged);
    on<PriorityChanged>(_onPriorityChanged);
    on<DueDateChanged>(_onDueDateChanged);
    on<StatusChanged>(_onStatusChanged);
    on<SubmitCreateTask>(_onSubmitCreateTask);
    on<SubmitUpdateTask>(_onSubmitUpdateTask);
    on<ResetForm>(_onResetForm);
    on<ClearFormMessage>(_onClearFormMessage);
  }

  final CreateTaskUseCase _createTaskUseCase;
  final UpdateTaskUseCase _updateTaskUseCase;

  static const AssignedUser _defaultAssignee = AssignedUser(
    id: 'u1',
    name: 'Alex Morgan',
    email: 'alex@example.com',
  );

  void _onInitializeForm(InitializeForm event, Emitter<TaskFormState> emit) {
    if (event.mode == TaskFormMode.edit && event.existingTask != null) {
      final task = event.existingTask!;
      emit(
        TaskFormEditing(
          mode: TaskFormMode.edit,
          taskId: task.id,
          existingTask: task,
          title: task.title,
          description: task.description,
          priority: task.priority,
          status: task.status,
          dueDate: task.dueDate,
        ),
      );
      return;
    }

    final tomorrow = DateTime.now().add(const Duration(days: 1));
    emit(
      TaskFormEditing(
        mode: TaskFormMode.create,
        title: '',
        description: '',
        priority: TaskPriority.medium,
        status: TaskStatus.pending,
        dueDate: DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
      ),
    );
  }

  void _onTitleChanged(TitleChanged event, Emitter<TaskFormState> emit) {
    final form = _currentForm;
    if (form == null) return;

    emit(
      form.copyWith(
        title: event.title,
        titleError: TaskFormValidator.validateTitle(event.title),
        clearSubmitError: true,
      ),
    );
  }

  void _onDescriptionChanged(
    DescriptionChanged event,
    Emitter<TaskFormState> emit,
  ) {
    final form = _currentForm;
    if (form == null) return;

    emit(
      form.copyWith(
        description: event.description,
        descriptionError: TaskFormValidator.validateDescription(
          event.description,
        ),
        clearSubmitError: true,
      ),
    );
  }

  void _onPriorityChanged(PriorityChanged event, Emitter<TaskFormState> emit) {
    final form = _currentForm;
    if (form == null) return;

    emit(
      form.copyWith(
        priority: event.priority,
        clearPriorityError: true,
        clearSubmitError: true,
      ),
    );
  }

  void _onDueDateChanged(DueDateChanged event, Emitter<TaskFormState> emit) {
    final form = _currentForm;
    if (form == null) return;

    emit(
      form.copyWith(
        dueDate: event.dueDate,
        dueDateError: TaskFormValidator.validateDueDate(event.dueDate),
        clearSubmitError: true,
      ),
    );
  }

  void _onStatusChanged(StatusChanged event, Emitter<TaskFormState> emit) {
    final form = _currentForm;
    if (form == null) return;

    emit(form.copyWith(status: event.status, clearSubmitError: true));
  }

  Future<void> _onSubmitCreateTask(
    SubmitCreateTask event,
    Emitter<TaskFormState> emit,
  ) async {
    final form = _currentForm;
    if (form == null || form.mode != TaskFormMode.create) return;
    if (state is TaskFormSubmitting) return;

    final validated = _validate(form);
    if (!validated.isValid) {
      emit(TaskFormValidationError(form: validated));
      emit(validated);
      return;
    }

    emit(TaskFormSubmitting(form: validated));

    final now = DateTime.now().toUtc();
    final draft = Task(
      id: 0,
      title: validated.title.trim(),
      description: validated.description.trim(),
      priority: validated.priority!,
      status: TaskStatus.pending,
      dueDate: validated.dueDate!,
      assignedUser: _defaultAssignee,
      createdAt: now,
      updatedAt: now,
      completed: false,
    );

    final result = await _createTaskUseCase(CreateTaskParams(task: draft));

    result.fold(
      (failure) {
        emit(TaskFormFailure(message: failure.message, form: validated));
        emit(validated.copyWith(submitError: failure.message));
      },
      (task) {
        emit(
          TaskFormSuccess(
            task: task,
            message: MessageKeys.taskCreatedSuccess,
            mode: TaskFormMode.create,
          ),
        );
      },
    );
  }

  Future<void> _onSubmitUpdateTask(
    SubmitUpdateTask event,
    Emitter<TaskFormState> emit,
  ) async {
    final form = _currentForm;
    if (form == null || form.mode != TaskFormMode.edit) return;
    if (state is TaskFormSubmitting) return;

    final validated = _validate(form);
    if (!validated.isValid) {
      emit(TaskFormValidationError(form: validated));
      emit(validated);
      return;
    }

    emit(TaskFormSubmitting(form: validated));

    final existing = form.existingTask!;
    final completed = validated.status == TaskStatus.completed;
    final draft = existing.copyWith(
      title: validated.title.trim(),
      description: validated.description.trim(),
      priority: validated.priority!,
      status: validated.status,
      dueDate: validated.dueDate!,
      completed: completed,
      updatedAt: DateTime.now().toUtc(),
    );

    final result = await _updateTaskUseCase(UpdateTaskParams(task: draft));

    result.fold(
      (failure) {
        emit(TaskFormFailure(message: failure.message, form: validated));
        emit(validated.copyWith(submitError: failure.message));
      },
      (task) {
        emit(
          TaskFormSuccess(
            task: task,
            message: MessageKeys.taskUpdatedSuccess,
            mode: TaskFormMode.edit,
          ),
        );
      },
    );
  }

  void _onResetForm(ResetForm event, Emitter<TaskFormState> emit) {
    emit(const TaskFormInitial());
  }

  void _onClearFormMessage(
    ClearFormMessage event,
    Emitter<TaskFormState> emit,
  ) {
    final form = _currentForm;
    if (form == null) return;
    emit(form.copyWith(clearSubmitError: true));
  }

  TaskFormEditing? get _currentForm {
    final current = state;
    if (current is TaskFormEditing) return current;
    if (current is TaskFormSubmitting) return current.form;
    if (current is TaskFormFailure) return current.form;
    if (current is TaskFormValidationError) return current.form;
    return null;
  }

  TaskFormEditing _validate(TaskFormEditing form) {
    return form.copyWith(
      titleError: TaskFormValidator.validateTitle(form.title),
      descriptionError: TaskFormValidator.validateDescription(form.description),
      priorityError: TaskFormValidator.validatePriority(form.priority),
      dueDateError: TaskFormValidator.validateDueDate(form.dueDate),
      clearSubmitError: true,
    );
  }
}
