import 'package:dartz/dartz.dart' hide Task;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/core/errors/server_failure.dart';
import 'package:team_workspace/features/task/domain/usecases/create_task_usecase.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockTaskRepository repository;
  late CreateTaskUseCase useCase;

  setUpAll(() {
    registerFallbackValue(FakeData.task());
  });

  setUp(() {
    repository = MockTaskRepository();
    useCase = CreateTaskUseCase(repository);
  });

  group('CreateTaskUseCase', () {
    test('returns created task on success', () async {
      final created = FakeData.task(id: 10, title: 'New');
      when(
        () => repository.createTask(any()),
      ).thenAnswer((_) async => Right(created));

      final result = await useCase(
        CreateTaskParams(task: FakeData.task(id: 0)),
      );

      expect(result, Right(created));
      verify(() => repository.createTask(any())).called(1);
    });

    test('returns Failure on repository error', () async {
      when(() => repository.createTask(any())).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Create failed')),
      );

      final result = await useCase(CreateTaskParams(task: FakeData.task()));

      expect(result, const Left(ServerFailure(message: 'Create failed')));
    });
  });
}
