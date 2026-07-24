import 'package:equatable/equatable.dart';
import 'package:team_workspace/features/task/domain/entities/task.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';
import 'package:team_workspace/features/task/presentation/bloc/task_form/task_form_event.dart';

sealed class TaskFormState extends Equatable {
  const TaskFormState();

  @override
  List<Object?> get props => [];
}

class TaskFormInitial extends TaskFormState {
  const TaskFormInitial();
}

/// Active form editing state with field values and optional field errors.
class TaskFormEditing extends TaskFormState {
  const TaskFormEditing({
    required this.mode,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.dueDate,
    this.taskId,
    this.existingTask,
    this.titleError,
    this.descriptionError,
    this.priorityError,
    this.dueDateError,
    this.submitError,
  });

  final TaskFormMode mode;
  final int? taskId;
  final Task? existingTask;
  final String title;
  final String description;
  final TaskPriority? priority;
  final TaskStatus status;
  final DateTime? dueDate;
  final String? titleError;
  final String? descriptionError;
  final String? priorityError;
  final String? dueDateError;
  final String? submitError;

  bool get isEditMode => mode == TaskFormMode.edit;

  bool get isValid =>
      titleError == null &&
      descriptionError == null &&
      priorityError == null &&
      dueDateError == null &&
      title.trim().isNotEmpty &&
      description.trim().isNotEmpty &&
      priority != null &&
      dueDate != null;

  TaskFormEditing copyWith({
    TaskFormMode? mode,
    int? taskId,
    Task? existingTask,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    Object? titleError = _unset,
    Object? descriptionError = _unset,
    Object? priorityError = _unset,
    Object? dueDateError = _unset,
    Object? submitError = _unset,
    bool clearTitleError = false,
    bool clearDescriptionError = false,
    bool clearPriorityError = false,
    bool clearDueDateError = false,
    bool clearSubmitError = false,
  }) {
    return TaskFormEditing(
      mode: mode ?? this.mode,
      taskId: taskId ?? this.taskId,
      existingTask: existingTask ?? this.existingTask,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      titleError: clearTitleError
          ? null
          : identical(titleError, _unset)
          ? this.titleError
          : titleError as String?,
      descriptionError: clearDescriptionError
          ? null
          : identical(descriptionError, _unset)
          ? this.descriptionError
          : descriptionError as String?,
      priorityError: clearPriorityError
          ? null
          : identical(priorityError, _unset)
          ? this.priorityError
          : priorityError as String?,
      dueDateError: clearDueDateError
          ? null
          : identical(dueDateError, _unset)
          ? this.dueDateError
          : dueDateError as String?,
      submitError: clearSubmitError
          ? null
          : identical(submitError, _unset)
          ? this.submitError
          : submitError as String?,
    );
  }

  static const Object _unset = Object();

  @override
  List<Object?> get props => [
    mode,
    taskId,
    existingTask,
    title,
    description,
    priority,
    status,
    dueDate,
    titleError,
    descriptionError,
    priorityError,
    dueDateError,
    submitError,
  ];
}

class TaskFormSubmitting extends TaskFormState {
  const TaskFormSubmitting({required this.form});

  final TaskFormEditing form;

  @override
  List<Object?> get props => [form];
}

class TaskFormSuccess extends TaskFormState {
  const TaskFormSuccess({
    required this.task,
    required this.message,
    required this.mode,
  });

  final Task task;
  final String message;
  final TaskFormMode mode;

  @override
  List<Object?> get props => [task, message, mode];
}

class TaskFormFailure extends TaskFormState {
  const TaskFormFailure({required this.message, required this.form});

  final String message;
  final TaskFormEditing form;

  @override
  List<Object?> get props => [message, form];
}

class TaskFormValidationError extends TaskFormState {
  const TaskFormValidationError({required this.form});

  final TaskFormEditing form;

  @override
  List<Object?> get props => [form];
}
