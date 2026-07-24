import 'package:dartz/dartz.dart' hide Task;
import 'package:equatable/equatable.dart';
import 'package:team_workspace/core/errors/failure.dart';
import 'package:team_workspace/core/usecases/usecase.dart';
import 'package:team_workspace/features/task/domain/entities/task.dart';
import 'package:team_workspace/features/task/domain/repositories/task_repository.dart';

class GetTaskDetailsUseCase implements UseCase<Task, GetTaskDetailsParams> {
  GetTaskDetailsUseCase(this._repository);

  final TaskRepository _repository;

  @override
  Future<Either<Failure, Task>> call(GetTaskDetailsParams params) {
    return _repository.getTaskDetails(params.id);
  }
}

class GetTaskDetailsParams extends Equatable {
  const GetTaskDetailsParams({required this.id});

  final int id;

  @override
  List<Object?> get props => [id];
}
