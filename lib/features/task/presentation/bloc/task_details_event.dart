import 'package:equatable/equatable.dart';
import 'package:team_workspace/features/task/domain/entities/task.dart';

sealed class TaskDetailsEvent extends Equatable {
  const TaskDetailsEvent();

  @override
  List<Object?> get props => [];
}

class LoadTaskDetails extends TaskDetailsEvent {
  const LoadTaskDetails(this.taskId);

  final int taskId;

  @override
  List<Object?> get props => [taskId];
}

class RefreshTaskDetails extends TaskDetailsEvent {
  const RefreshTaskDetails(this.taskId);

  final int taskId;

  @override
  List<Object?> get props => [taskId];
}

class MarkCompleted extends TaskDetailsEvent {
  const MarkCompleted();
}

class ReopenTask extends TaskDetailsEvent {
  const ReopenTask();
}

class RetryLoading extends TaskDetailsEvent {
  const RetryLoading();
}

class ClearStatusUpdateMessage extends TaskDetailsEvent {
  const ClearStatusUpdateMessage();
}

/// Applies an externally edited task without a full remote reload.
class TaskDetailsContentUpdated extends TaskDetailsEvent {
  const TaskDetailsContentUpdated(this.task);

  final Task task;

  @override
  List<Object?> get props => [task];
}
