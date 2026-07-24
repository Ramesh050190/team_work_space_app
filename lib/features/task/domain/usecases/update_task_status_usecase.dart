import 'package:dartz/dartz.dart' hide Task;
import 'package:equatable/equatable.dart';
import 'package:team_workspace/core/errors/failure.dart';
import 'package:team_workspace/core/usecases/usecase.dart';
import 'package:team_workspace/features/task/domain/entities/task.dart';
import 'package:team_workspace/features/task/domain/repositories/task_repository.dart';

class UpdateTaskStatusUseCase implements UseCase<Task, UpdateTaskStatusParams> {
  UpdateTaskStatusUseCase(this._repository);

  final TaskRepository _repository;

  @override
  Future<Either<Failure, Task>> call(UpdateTaskStatusParams params) {
    return _repository.updateTaskStatus(
      id: params.id,
      completed: params.completed,
    );
  }
}

class UpdateTaskStatusParams extends Equatable {
  const UpdateTaskStatusParams({required this.id, required this.completed});

  final int id;
  final bool completed;

  @override
  List<Object?> get props => [id, completed];
}
