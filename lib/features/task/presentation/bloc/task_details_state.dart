import 'package:equatable/equatable.dart';
import 'package:team_workspace/core/constants/message_keys.dart';
import 'package:team_workspace/features/task/domain/entities/task.dart';

sealed class TaskDetailsState extends Equatable {
  const TaskDetailsState();

  @override
  List<Object?> get props => [];
}

class TaskDetailsInitial extends TaskDetailsState {
  const TaskDetailsInitial();
}

class TaskDetailsLoading extends TaskDetailsState {
  const TaskDetailsLoading();
}

class TaskDetailsLoaded extends TaskDetailsState {
  const TaskDetailsLoaded({required this.task, this.statusUpdateMessage});

  final Task task;
  final String? statusUpdateMessage;

  TaskDetailsLoaded copyWith({
    Task? task,
    String? statusUpdateMessage,
    bool clearStatusUpdateMessage = false,
  }) {
    return TaskDetailsLoaded(
      task: task ?? this.task,
      statusUpdateMessage: clearStatusUpdateMessage
          ? null
          : statusUpdateMessage ?? this.statusUpdateMessage,
    );
  }

  @override
  List<Object?> get props => [task, statusUpdateMessage];
}

class TaskDetailsUpdating extends TaskDetailsState {
  const TaskDetailsUpdating({required this.task, required this.previousTask});

  final Task task;
  final Task previousTask;

  @override
  List<Object?> get props => [task, previousTask];
}

class TaskDetailsSuccess extends TaskDetailsState {
  const TaskDetailsSuccess({required this.task, required this.message});

  final Task task;
  final String message;

  @override
  List<Object?> get props => [task, message];
}

class TaskDetailsFailure extends TaskDetailsState {
  const TaskDetailsFailure({required this.message, this.cachedTask});

  final String message;
  final Task? cachedTask;

  @override
  List<Object?> get props => [message, cachedTask];
}

class TaskDetailsEmpty extends TaskDetailsState {
  const TaskDetailsEmpty({this.message = MessageKeys.taskNotFound});

  final String message;

  @override
  List<Object?> get props => [message];
}
