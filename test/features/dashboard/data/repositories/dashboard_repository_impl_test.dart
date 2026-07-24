import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/core/errors/network_failure.dart';
import 'package:team_workspace/core/errors/server_failure.dart';
import 'package:team_workspace/core/exceptions/server_exception.dart';
import 'package:team_workspace/core/network/network_info.dart';
import 'package:team_workspace/features/dashboard/data/datasources/dashboard_local_datasource.dart';
import 'package:team_workspace/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:team_workspace/features/dashboard/data/models/task_model.dart';
import 'package:team_workspace/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:team_workspace/features/dashboard/domain/entities/paginated_tasks_page.dart';
import 'package:team_workspace/features/dashboard/domain/entities/task_entity.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';

class _MockRemote extends Mock implements DashboardRemoteDataSource {}

class _MockLocal extends Mock implements DashboardLocalDataSource {}

class _MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late _MockRemote remote;
  late _MockLocal local;
  late _MockNetworkInfo networkInfo;
  late DashboardRepositoryImpl repository;

  final model = TaskModel(
    id: '1',
    title: 'Complete Flutter App',
    description: 'Implement dashboard',
    status: 'pending',
    priority: 'high',
    createdAt: DateTime.parse('2026-01-01'),
  );

  final cachedPage = PaginatedTasksPage(
    tasks: [
      TaskEntity(
        id: '1',
        title: 'Cached task',
        description: 'From Hive',
        status: 'pending',
        priority: 'medium',
        createdAt: DateTime.parse('2026-01-01'),
      ),
    ],
    page: 1,
    totalPages: 1,
  );

  setUp(() {
    remote = _MockRemote();
    local = _MockLocal();
    networkInfo = _MockNetworkInfo();
    repository = DashboardRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      networkInfo: networkInfo,
    );
    when(
      () => local.cacheTasks(any(), page: any(named: 'page')),
    ).thenAnswer((_) async {});
  });

  void stubCache([PaginatedTasksPage? page]) {
    when(
      () => local.getCachedTasks(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        searchQuery: any(named: 'searchQuery'),
        status: any(named: 'status'),
        priority: any(named: 'priority'),
      ),
    ).thenAnswer((_) async => page ?? cachedPage);
  }

  test('returns cached tasks when offline', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => false);
    stubCache();

    final result = await repository.getTasks(page: 1, limit: 20);

    expect(result.isRight(), isTrue);
    result.fold((_) => fail('expected cache'), (page) {
      expect(page.tasks.single.title, 'Cached task');
    });
    verifyNever(
      () => remote.getTasks(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        searchQuery: any(named: 'searchQuery'),
        status: any(named: 'status'),
        priority: any(named: 'priority'),
      ),
    );
  });

  test('returns NetworkFailure when offline and cache empty', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => false);
    stubCache(const PaginatedTasksPage(tasks: [], page: 1, totalPages: 1));

    final result = await repository.getTasks(page: 1, limit: 20);

    expect(
      result,
      const Left(NetworkFailure(message: 'No internet connection')),
    );
  });

  test('caches remote page when online', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => true);
    when(
      () => remote.getTasks(
        page: 1,
        limit: 20,
        searchQuery: any(named: 'searchQuery'),
        status: any(named: 'status'),
        priority: any(named: 'priority'),
      ),
    ).thenAnswer(
      (_) async =>
          DashboardTasksResponse(tasks: [model], page: 1, totalPages: 5),
    );

    final result = await repository.getTasks(page: 1, limit: 20);

    expect(result.isRight(), isTrue);
    verify(() => local.cacheTasks(any(), page: 1)).called(1);
  });

  test('passes search, status and priority filters to remote', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => true);
    when(
      () => remote.getTasks(
        page: 1,
        limit: 20,
        searchQuery: 'flutter',
        status: TaskStatus.pending,
        priority: TaskPriority.high,
      ),
    ).thenAnswer(
      (_) async =>
          DashboardTasksResponse(tasks: [model], page: 1, totalPages: 1),
    );

    final result = await repository.getTasks(
      page: 1,
      limit: 20,
      searchQuery: 'flutter',
      status: TaskStatus.pending,
      priority: TaskPriority.high,
    );

    expect(result.isRight(), isTrue);
    verify(
      () => remote.getTasks(
        page: 1,
        limit: 20,
        searchQuery: 'flutter',
        status: TaskStatus.pending,
        priority: TaskPriority.high,
      ),
    ).called(1);
  });

  test('falls back to cache when remote throws ServerException', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => true);
    when(
      () => remote.getTasks(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        searchQuery: any(named: 'searchQuery'),
        status: any(named: 'status'),
        priority: any(named: 'priority'),
      ),
    ).thenThrow(const ServerException(message: 'Boom', statusCode: 500));
    stubCache();

    final result = await repository.getTasks(page: 1, limit: 20);

    expect(result.isRight(), isTrue);
    result.fold((_) => fail('expected cache fallback'), (page) {
      expect(page.tasks.single.title, 'Cached task');
    });
  });

  test('returns ServerFailure when remote fails and cache empty', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => true);
    when(
      () => remote.getTasks(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        searchQuery: any(named: 'searchQuery'),
        status: any(named: 'status'),
        priority: any(named: 'priority'),
      ),
    ).thenThrow(const ServerException(message: 'Boom', statusCode: 500));
    stubCache(const PaginatedTasksPage(tasks: [], page: 1, totalPages: 1));

    final result = await repository.getTasks(page: 1, limit: 20);

    expect(result, const Left(ServerFailure(message: 'Boom', statusCode: 500)));
  });

  test('cacheOnly reads Hive without hitting network', () async {
    stubCache();

    final result = await repository.getTasks(
      page: 1,
      limit: 20,
      cacheOnly: true,
    );

    expect(result.isRight(), isTrue);
    verifyNever(() => networkInfo.isConnected);
    verifyNever(
      () => remote.getTasks(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        searchQuery: any(named: 'searchQuery'),
        status: any(named: 'status'),
        priority: any(named: 'priority'),
      ),
    );
  });
}
