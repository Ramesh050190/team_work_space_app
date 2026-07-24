import 'package:dartz/dartz.dart' hide Task;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/core/errors/network_failure.dart';
import 'package:team_workspace/core/errors/server_failure.dart';
import 'package:team_workspace/core/exceptions/server_exception.dart';
import 'package:team_workspace/core/network/network_info.dart';
import 'package:team_workspace/features/dashboard/domain/entities/task_query.dart';
import 'package:team_workspace/features/task/data/datasources/task_local_datasource.dart';
import 'package:team_workspace/features/task/data/datasources/task_remote_datasource.dart';
import 'package:team_workspace/features/task/data/models/pending_sync_model.dart';
import 'package:team_workspace/features/task/data/models/task_model.dart';
import 'package:team_workspace/features/task/data/repositories/task_repository_impl.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';

class _MockRemoteDataSource extends Mock implements TaskRemoteDataSource {}

class _MockLocalDataSource extends Mock implements TaskLocalDataSource {}

class _MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late _MockRemoteDataSource remoteDataSource;
  late _MockLocalDataSource localDataSource;
  late _MockNetworkInfo networkInfo;
  late TaskRepositoryImpl repository;

  final taskModel = TaskModel(
    id: 1,
    title: 'Sample',
    description: 'Description',
    priority: TaskPriority.medium,
    status: TaskStatus.pending,
    dueDate: DateTime.parse('2026-07-25T00:00:00.000Z'),
    assignedUser: const AssignedUserModel(
      id: 'u1',
      name: 'Alex',
      email: 'alex@example.com',
    ),
    createdAt: DateTime.parse('2026-07-20T08:00:00.000Z'),
    updatedAt: DateTime.parse('2026-07-20T08:00:00.000Z'),
    completed: false,
  );

  setUpAll(() {
    registerFallbackValue(taskModel);
    registerFallbackValue(const TaskQuery());
    registerFallbackValue(
      PendingSyncModel(
        operationId: 'op',
        taskId: 1,
        operationType: PendingOperationType.update,
        payload: const {},
        createdAt: DateTime.parse('2026-07-20T08:00:00.000Z'),
      ),
    );
  });

  setUp(() {
    remoteDataSource = _MockRemoteDataSource();
    localDataSource = _MockLocalDataSource();
    networkInfo = _MockNetworkInfo();
    when(
      () => localDataSource.getCachedTaskDetails(any()),
    ).thenAnswer((_) async => null);
    repository = TaskRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
      networkInfo: networkInfo,
    );
  });

  group('getTaskDetails', () {
    test('returns remote task and caches it when online', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(
        () => remoteDataSource.getTaskDetails(1),
      ).thenAnswer((_) async => taskModel);
      when(
        () => localDataSource.cacheTaskDetails(taskModel),
      ).thenAnswer((_) async {});

      final result = await repository.getTaskDetails(1);

      expect(result, isA<Right>());
      result.fold((_) => fail('Expected success'), (task) {
        expect(task.id, 1);
        expect(task.title, 'Sample');
      });
      verify(() => localDataSource.cacheTaskDetails(taskModel)).called(1);
    });

    test('returns cached task when offline and cache exists', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => false);
      when(
        () => localDataSource.getCachedTaskDetails(1),
      ).thenAnswer((_) async => taskModel);

      final result = await repository.getTaskDetails(1);

      expect(result, isA<Right>());
      verifyNever(() => remoteDataSource.getTaskDetails(any()));
    });

    test('returns NetworkFailure when offline and cache is missing', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => false);
      when(
        () => localDataSource.getCachedTaskDetails(1),
      ).thenAnswer((_) async => null);

      final result = await repository.getTaskDetails(1);

      expect(result, equals(const Left(NetworkFailure())));
    });

    test('falls back to cache when remote throws ServerException', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(() => remoteDataSource.getTaskDetails(1)).thenThrow(
        const ServerException(message: 'Server down', statusCode: 500),
      );
      when(
        () => localDataSource.getCachedTaskDetails(1),
      ).thenAnswer((_) async => taskModel);

      final result = await repository.getTaskDetails(1);

      expect(result, isA<Right>());
    });

    test(
      'returns ServerFailure when remote fails and cache is empty',
      () async {
        when(() => networkInfo.isConnected).thenAnswer((_) async => true);
        when(() => remoteDataSource.getTaskDetails(1)).thenThrow(
          const ServerException(message: 'Server down', statusCode: 500),
        );
        when(
          () => localDataSource.getCachedTaskDetails(1),
        ).thenAnswer((_) async => null);

        final result = await repository.getTaskDetails(1);

        expect(
          result,
          equals(
            const Left(ServerFailure(message: 'Server down', statusCode: 500)),
          ),
        );
      },
    );
  });

  group('updateTaskStatus', () {
    test('returns updated task when online', () async {
      final updated = taskModel.copyWith(
        completed: true,
        status: TaskStatus.completed,
      );

      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(
        () => remoteDataSource.updateTaskStatus(id: 1, completed: true),
      ).thenAnswer((_) async => updated);
      when(
        () => localDataSource.cacheTaskDetails(updated),
      ).thenAnswer((_) async {});

      final result = await repository.updateTaskStatus(id: 1, completed: true);

      expect(result, isA<Right>());
    });

    test('queues status change offline and updates cache', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => false);
      when(
        () => localDataSource.getCachedTaskDetails(1),
      ).thenAnswer((_) async => taskModel);
      when(
        () => localDataSource.cacheTaskDetails(any()),
      ).thenAnswer((_) async {});
      when(
        () => localDataSource.enqueuePendingOperation(any()),
      ).thenAnswer((_) async {});

      final result = await repository.updateTaskStatus(id: 1, completed: true);

      expect(result, isA<Right>());
      verify(() => localDataSource.enqueuePendingOperation(any())).called(1);
      verify(() => localDataSource.cacheTaskDetails(any())).called(1);
    });
  });

  group('createTask', () {
    test('creates remotely and caches result', () async {
      final created = taskModel.copyWith(id: 99, title: 'Created');

      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(
        () => remoteDataSource.createTask(any()),
      ).thenAnswer((_) async => created);
      when(
        () => localDataSource.cacheTaskDetails(created),
      ).thenAnswer((_) async {});

      final result = await repository.createTask(taskModel);

      expect(result, isA<Right>());
      verify(() => localDataSource.cacheTaskDetails(created)).called(1);
    });

    test('queues create offline and caches local task', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => false);
      when(
        () => localDataSource.cacheTaskDetails(any()),
      ).thenAnswer((_) async {});
      when(
        () => localDataSource.enqueuePendingOperation(any()),
      ).thenAnswer((_) async {});

      final result = await repository.createTask(taskModel.copyWith(id: 0));

      expect(result, isA<Right>());
      verify(() => localDataSource.enqueuePendingOperation(any())).called(1);
    });
  });

  group('updateTask', () {
    test('updates remotely and caches result', () async {
      final updated = taskModel.copyWith(title: 'Updated');

      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(
        () => remoteDataSource.updateTask(any()),
      ).thenAnswer((_) async => updated);
      when(
        () => localDataSource.cacheTaskDetails(updated),
      ).thenAnswer((_) async {});

      final result = await repository.updateTask(taskModel);

      expect(result, isA<Right>());
      verify(() => localDataSource.cacheTaskDetails(updated)).called(1);
    });
  });

  group('searchTasks / filterTasks', () {
    test('fetches from API and caches list when online', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(() => remoteDataSource.queryTasks(any())).thenAnswer(
        (_) async => PaginatedTaskModels(
          tasks: [taskModel],
          page: 1,
          limit: 10,
          total: 1,
          hasMore: false,
        ),
      );
      when(
        () => localDataSource.getCachedTaskList(),
      ).thenAnswer((_) async => const []);
      when(() => localDataSource.cacheTaskList(any())).thenAnswer((_) async {});

      final result = await repository.searchTasks(
        const TaskQuery(searchQuery: 'Sample'),
      );

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected success'), (page) {
        expect(page.tasks, hasLength(1));
        expect(page.tasks.first.title, 'Sample');
      });
      verify(() => localDataSource.cacheTaskList(any())).called(1);
    });

    test('falls back to cached list when offline', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => false);
      when(
        () => localDataSource.getCachedTaskList(),
      ).thenAnswer((_) async => [taskModel]);

      final result = await repository.filterTasks(const TaskQuery());

      expect(result.isRight(), isTrue);
      verifyNever(() => remoteDataSource.queryTasks(any()));
    });

    test('returns NetworkFailure when offline and cache empty', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => false);
      when(
        () => localDataSource.getCachedTaskList(),
      ).thenAnswer((_) async => const []);

      final result = await repository.searchTasks(const TaskQuery());

      expect(result, equals(const Left(NetworkFailure())));
    });
  });
}
