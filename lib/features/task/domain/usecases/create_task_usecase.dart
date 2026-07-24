import 'package:dartz/dartz.dart' hide Task;
import 'package:equatable/equatable.dart';
import 'package:team_workspace/core/errors/failure.dart';
import 'package:team_workspace/core/usecases/usecase.dart';
import 'package:team_workspace/features/task/domain/entities/task.dart';
import 'package:team_workspace/features/task/domain/repositories/task_repository.dart';

/// Creates a new task via the repository.
class CreateTaskUseCase implements UseCase<Task, CreateTaskParams> {
  CreateTaskUseCase(this._repository);

  final TaskRepository _repository;

  @override
  Future<Either<Failure, Task>> call(CreateTaskParams params) {
    return _repository.createTask(params.task);
  }
}

class CreateTaskParams extends Equatable {
  const CreateTaskParams({required this.task});

  final Task task;

  @override
  List<Object?> get props => [task];
}
