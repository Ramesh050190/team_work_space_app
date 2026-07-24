import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/core/errors/server_failure.dart';
import 'package:team_workspace/features/dashboard/domain/entities/paginated_tasks_page.dart';
import 'package:team_workspace/features/dashboard/domain/entities/task_entity.dart';
import 'package:team_workspace/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:team_workspace/features/dashboard/domain/usecases/get_tasks_usecase.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';

class _MockDashboardRepository extends Mock implements DashboardRepository {}

void main() {
  late _MockDashboardRepository repository;
  late GetTasksUseCase useCase;

  final sampleTask = TaskEntity(
    id: '1',
    title: 'Complete Flutter App',
    description: 'Implement dashboard',
    status: 'pending',
    createdAt: DateTime.parse('2026-01-01'),
  );

  final page = PaginatedTasksPage(tasks: [sampleTask], page: 1, totalPages: 5);

  setUp(() {
    repository = _MockDashboardRepository();
    useCase = GetTasksUseCase(repository);
  });

  test('returns paginated tasks on success', () async {
    when(
      () => repository.getTasks(
        page: 1,
        limit: 20,
        cacheOnly: false,
        searchQuery: '',
        status: null,
        priority: null,
      ),
    ).thenAnswer((_) async => Right(page));

    final result = await useCase(const GetTasksParams(page: 1, limit: 20));

    expect(result, Right(page));
    verify(
      () => repository.getTasks(
        page: 1,
        limit: 20,
        cacheOnly: false,
        searchQuery: '',
        status: null,
        priority: null,
      ),
    ).called(1);
  });

  test('forwards search and filters together', () async {
    when(
      () => repository.getTasks(
        page: 1,
        limit: 20,
        cacheOnly: false,
        searchQuery: 'flutter',
        status: TaskStatus.pending,
        priority: TaskPriority.high,
      ),
    ).thenAnswer((_) async => Right(page));

    final result = await useCase(
      const GetTasksParams(
        page: 1,
        limit: 20,
        searchQuery: 'flutter',
        status: TaskStatus.pending,
        priority: TaskPriority.high,
      ),
    );

    expect(result.isRight(), isTrue);
    verify(
      () => repository.getTasks(
        page: 1,
        limit: 20,
        cacheOnly: false,
        searchQuery: 'flutter',
        status: TaskStatus.pending,
        priority: TaskPriority.high,
      ),
    ).called(1);
  });

  test('returns Failure when repository fails', () async {
    when(
      () => repository.getTasks(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        cacheOnly: any(named: 'cacheOnly'),
        searchQuery: any(named: 'searchQuery'),
        status: any(named: 'status'),
        priority: any(named: 'priority'),
      ),
    ).thenAnswer(
      (_) async => const Left(ServerFailure(message: 'Server error')),
    );

    final result = await useCase(const GetTasksParams());

    expect(result.isLeft(), isTrue);
  });

  test('forwards cacheOnly and GetTasksParams props', () async {
    when(
      () => repository.getTasks(
        page: 2,
        limit: 5,
        cacheOnly: true,
        searchQuery: '',
        status: null,
        priority: null,
      ),
    ).thenAnswer((_) async => Right(page));

    const params = GetTasksParams(page: 2, limit: 5, cacheOnly: true);
    const same = GetTasksParams(page: 2, limit: 5, cacheOnly: true);
    const different = GetTasksParams(page: 3, limit: 5, cacheOnly: true);

    expect(params, equals(same));
    expect(params, isNot(equals(different)));

    final result = await useCase(params);
    expect(result.isRight(), isTrue);
  });

  test('GetTasksParams props include search status and priority', () {
    const a = GetTasksParams(
      page: 2,
      limit: 10,
      cacheOnly: true,
      searchQuery: 'flutter',
      status: TaskStatus.pending,
      priority: TaskPriority.high,
    );
    const b = GetTasksParams(
      page: 2,
      limit: 10,
      cacheOnly: true,
      searchQuery: 'flutter',
      status: TaskStatus.pending,
      priority: TaskPriority.high,
    );

    expect(a, equals(b));
    expect(a.props, [
      2,
      10,
      true,
      'flutter',
      TaskStatus.pending,
      TaskPriority.high,
    ]);
  });
}
