import 'package:dartz/dartz.dart' hide Task;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/core/errors/server_failure.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';
import 'package:team_workspace/features/task/domain/usecases/get_task_details_usecase.dart';
import 'package:team_workspace/features/task/domain/usecases/update_task_status_usecase.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockTaskRepository repository;

  setUp(() {
    repository = MockTaskRepository();
  });

  group('GetTaskDetailsUseCase', () {
    late GetTaskDetailsUseCase useCase;

    setUp(() {
      useCase = GetTaskDetailsUseCase(repository);
    });

    test('returns task when repository succeeds', () async {
      when(
        () => repository.getTaskDetails(1),
      ).thenAnswer((_) async => Right(FakeData.task()));

      final result = await useCase(const GetTaskDetailsParams(id: 1));

      expect(result, Right(FakeData.task()));
      verify(() => repository.getTaskDetails(1)).called(1);
    });

    test('returns Failure when repository fails', () async {
      when(() => repository.getTaskDetails(99)).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Not found')),
      );

      final result = await useCase(const GetTaskDetailsParams(id: 99));

      expect(result, const Left(ServerFailure(message: 'Not found')));
    });
  });

  group('UpdateTaskStatusUseCase', () {
    late UpdateTaskStatusUseCase useCase;

    setUp(() {
      useCase = UpdateTaskStatusUseCase(repository);
    });

    test('returns updated task when status change succeeds', () async {
      final completed = FakeData.task(
        completed: true,
        status: TaskStatus.completed,
      );
      when(
        () => repository.updateTaskStatus(id: 1, completed: true),
      ).thenAnswer((_) async => Right(completed));

      final result = await useCase(
        const UpdateTaskStatusParams(id: 1, completed: true),
      );

      expect(result, Right(completed));
      verify(
        () => repository.updateTaskStatus(id: 1, completed: true),
      ).called(1);
    });

    test('returns Failure when status change fails', () async {
      when(
        () => repository.updateTaskStatus(
          id: any(named: 'id'),
          completed: any(named: 'completed'),
        ),
      ).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Update failed')),
      );

      final result = await useCase(
        const UpdateTaskStatusParams(id: 1, completed: true),
      );

      expect(result, const Left(ServerFailure(message: 'Update failed')));
    });
  });
}
