import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/core/exceptions/cache_exception.dart';
import 'package:team_workspace/features/dashboard/data/datasources/dashboard_local_datasource_impl.dart';
import 'package:team_workspace/features/dashboard/data/models/task_model.dart'
    as dashboard;
import 'package:team_workspace/features/task/data/datasources/task_local_datasource.dart';
import 'package:team_workspace/features/task/data/models/task_model.dart';
import 'package:team_workspace/features/task/domain/entities/assigned_user.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';

class MockTaskLocalDataSource extends Mock implements TaskLocalDataSource {}

void main() {
  late MockTaskLocalDataSource taskLocal;
  late DashboardLocalDataSourceImpl dataSource;

  TaskModel taskModel({
    int id = 1,
    String title = 'Flutter Task',
    TaskStatus status = TaskStatus.pending,
    TaskPriority priority = TaskPriority.medium,
    DateTime? updatedAt,
  }) {
    final stamp = DateTime.utc(2026, 7, 20, 8);
    return TaskModel(
      id: id,
      title: title,
      description: 'Details for task',
      priority: priority,
      status: status,
      dueDate: DateTime.utc(2026, 7, 25),
      assignedUser: const AssignedUser(
        id: 'u1',
        name: 'Alex',
        email: 'alex@example.com',
      ),
      createdAt: stamp,
      updatedAt: updatedAt ?? stamp,
      completed: status == TaskStatus.completed,
    );
  }

  setUpAll(() {
    registerFallbackValue(taskModel());
  });

  setUp(() {
    taskLocal = MockTaskLocalDataSource();
    dataSource = DashboardLocalDataSourceImpl(taskLocalDataSource: taskLocal);
    when(() => taskLocal.cacheTaskDetails(any())).thenAnswer((_) async {});
    when(() => taskLocal.cacheTaskList(any())).thenAnswer((_) async {});
    when(() => taskLocal.upsertCachedTask(any())).thenAnswer((_) async {});
  });

  group('getCachedTasks', () {
    test('filters by search status priority and paginates', () async {
      when(() => taskLocal.getCachedTaskList()).thenAnswer(
        (_) async => [
          taskModel(id: 1, title: 'Flutter A'),
          taskModel(
            id: 2,
            title: 'Dart B',
            status: TaskStatus.inProgress,
            priority: TaskPriority.high,
          ),
          taskModel(
            id: 3,
            title: 'Flutter C',
            status: TaskStatus.inProgress,
            priority: TaskPriority.high,
          ),
        ],
      );

      final page = await dataSource.getCachedTasks(
        page: 1,
        limit: 1,
        searchQuery: 'flutter',
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
      );

      expect(page.tasks, hasLength(1));
      expect(page.tasks.first.title, 'Flutter C');
      expect(page.totalPages, 1);
    });

    test('limit <= 0 yields totalPages 1', () async {
      when(() => taskLocal.getCachedTaskList()).thenAnswer(
        (_) async => [taskModel(), taskModel(id: 2)],
      );

      final page = await dataSource.getCachedTasks(page: 1, limit: 0);
      expect(page.totalPages, 1);
    });

    test('empty cache returns totalPages 1', () async {
      when(() => taskLocal.getCachedTaskList()).thenAnswer((_) async => []);
      final page = await dataSource.getCachedTasks(page: 1, limit: 10);
      expect(page.tasks, isEmpty);
      expect(page.totalPages, 1);
    });

    test('rethrows CacheException', () async {
      when(
        () => taskLocal.getCachedTaskList(),
      ).thenThrow(const CacheException(message: 'fail'));

      expect(
        () => dataSource.getCachedTasks(page: 1, limit: 10),
        throwsA(isA<CacheException>()),
      );
    });
  });

  group('cacheTasks', () {
    test('page 1 merges and skips fresher cache', () async {
      final olderRemote = dashboard.TaskModel(
        id: '1',
        title: 'Remote older',
        description: 'd',
        status: 'pending',
        createdAt: DateTime.utc(2026, 7, 1),
      );
      final newerCached = taskModel(
        id: 1,
        title: 'Cached newer',
        updatedAt: DateTime.utc(2026, 7, 30),
      );

      when(() => taskLocal.getCachedTaskList())
          .thenAnswer((_) async => [newerCached]);

      await dataSource.cacheTasks([olderRemote], page: 1);

      verify(() => taskLocal.cacheTaskList(any())).called(1);
      verifyNever(() => taskLocal.cacheTaskDetails(any()));
    });

    test('page > 1 upserts each task', () async {
      final remote = dashboard.TaskModel(
        id: '5',
        title: 'Page2',
        description: 'd',
        status: 'pending',
        createdAt: DateTime.utc(2026, 7, 1),
      );

      await dataSource.cacheTasks([remote], page: 2);

      verify(() => taskLocal.upsertCachedTask(any())).called(1);
      verify(() => taskLocal.cacheTaskDetails(any())).called(1);
    });
  });
}
