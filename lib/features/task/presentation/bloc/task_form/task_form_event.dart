import 'package:equatable/equatable.dart';
import 'package:team_workspace/features/task/domain/entities/task.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';

enum TaskFormMode { create, edit }

sealed class TaskFormEvent extends Equatable {
  const TaskFormEvent();

  @override
  List<Object?> get props => [];
}

class InitializeForm extends TaskFormEvent {
  const InitializeForm({required this.mode, this.existingTask});

  final TaskFormMode mode;
  final Task? existingTask;

  @override
  List<Object?> get props => [mode, existingTask];
}

class TitleChanged extends TaskFormEvent {
  const TitleChanged(this.title);

  final String title;

  @override
  List<Object?> get props => [title];
}

class DescriptionChanged extends TaskFormEvent {
  const DescriptionChanged(this.description);

  final String description;

  @override
  List<Object?> get props => [description];
}

class PriorityChanged extends TaskFormEvent {
  const PriorityChanged(this.priority);

  final TaskPriority priority;

  @override
  List<Object?> get props => [priority];
}

class DueDateChanged extends TaskFormEvent {
  const DueDateChanged(this.dueDate);

  final DateTime dueDate;

  @override
  List<Object?> get props => [dueDate];
}

class StatusChanged extends TaskFormEvent {
  const StatusChanged(this.status);

  final TaskStatus status;

  @override
  List<Object?> get props => [status];
}

class SubmitCreateTask extends TaskFormEvent {
  const SubmitCreateTask();
}

class SubmitUpdateTask extends TaskFormEvent {
  const SubmitUpdateTask();
}

class ResetForm extends TaskFormEvent {
  const ResetForm();
}

class ClearFormMessage extends TaskFormEvent {
  const ClearFormMessage();
}
