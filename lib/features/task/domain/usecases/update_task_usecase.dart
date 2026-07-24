import 'package:dartz/dartz.dart' hide Task;
import 'package:equatable/equatable.dart';
import 'package:team_workspace/core/errors/failure.dart';
import 'package:team_workspace/core/usecases/usecase.dart';
import 'package:team_workspace/features/task/domain/entities/task.dart';
import 'package:team_workspace/features/task/domain/repositories/task_repository.dart';

/// Updates an existing task via the repository.
class UpdateTaskUseCase implements UseCase<Task, UpdateTaskParams> {
  UpdateTaskUseCase(this._repository);

  final TaskRepository _repository;

  @override
  Future<Either<Failure, Task>> call(UpdateTaskParams params) {
    return _repository.updateTask(params.task);
  }
}

class UpdateTaskParams extends Equatable {
  const UpdateTaskParams({required this.task});

  final Task task;

  @override
  List<Object?> get props => [task];
}
