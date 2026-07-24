import 'package:dartz/dartz.dart' hide Task;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/core/errors/network_failure.dart';
import 'package:team_workspace/features/task/domain/usecases/update_task_usecase.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockTaskRepository repository;
  late UpdateTaskUseCase useCase;

  setUpAll(() {
    registerFallbackValue(FakeData.task());
  });

  setUp(() {
    repository = MockTaskRepository();
    useCase = UpdateTaskUseCase(repository);
  });

  group('UpdateTaskUseCase', () {
    test('returns updated task on success', () async {
      final updated = FakeData.task(title: 'Updated');
      when(
        () => repository.updateTask(any()),
      ).thenAnswer((_) async => Right(updated));

      final result = await useCase(UpdateTaskParams(task: FakeData.task()));

      expect(result, Right(updated));
      verify(() => repository.updateTask(any())).called(1);
    });

    test('returns Failure on repository error', () async {
      when(
        () => repository.updateTask(any()),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await useCase(UpdateTaskParams(task: FakeData.task()));

      expect(result, const Left(NetworkFailure()));
    });
  });
}
