import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/features/dashboard/data/datasources/dashboard_local_datasource_impl.dart';
import 'package:team_workspace/features/dashboard/data/models/task_model.dart'
    as dashboard;
import 'package:team_workspace/features/task/data/datasources/task_local_datasource.dart';
import 'package:team_workspace/features/task/data/models/task_model.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';

class _MockTaskLocalDataSource extends Mock implements TaskLocalDataSource {}

void main() {
  late _MockTaskLocalDataSource taskLocalDataSource;
  late DashboardLocalDataSourceImpl dataSource;

  final older = DateTime.utc(2026, 7, 20, 8);
  final newer = DateTime.utc(2026, 7, 22, 8);
  final futureStamp = DateTime.utc(2099, 1, 1);

  TaskModel taskModel({
    required int id,
    required String title,
    TaskStatus status = TaskStatus.pending,
    TaskPriority priority = TaskPriority.medium,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    final created = createdAt ?? older;
    return TaskModel(
      id: id,
      title: title,
      description: 'Description $id',
      priority: priority,
      status: status,
      dueDate: DateTime.utc(2026, 7, 25),
      assignedUser: const AssignedUserModel(
        id: 'u1',
        name: 'Alex',
        email: 'alex@example.com',
      ),
      createdAt: created,
      updatedAt: updatedAt ?? older,
      completed: status == TaskStatus.completed,
    );
  }

  setUpAll(() {
    registerFallbackValue(taskModel(id: 0, title: 'fallback'));
    registerFallbackValue(<TaskModel>[]);
  });

  setUp(() {
    taskLocalDataSource = _MockTaskLocalDataSource();
    dataSource = DashboardLocalDataSourceImpl(
      taskLocalDataSource: taskLocalDataSource,
    );
  });

  group('DashboardLocalDataSourceImpl.getCachedTasks', () {
    test('filters by search, status, priority and paginates', () async {
      when(() => taskLocalDataSource.getCachedTaskList()).thenAnswer(
        (_) async => [
          taskModel(
            id: 1,
            title: 'Alpha design',
            status: TaskStatus.pending,
            priority: TaskPriority.high,
          ),
          taskModel(
            id: 2,
            title: 'Beta design',
            status: TaskStatus.inProgress,
            priority: TaskPriority.high,
          ),
          taskModel(
            id: 3,
            title: 'Gamma design',
            status: TaskStatus.inProgress,
            priority: TaskPriority.high,
          ),
          taskModel(
            id: 4,
            title: 'Other work',
            status: TaskStatus.inProgress,
            priority: TaskPriority.high,
          ),
          taskModel(
            id: 5,
            title: 'Delta design',
            status: TaskStatus.inProgress,
            priority: TaskPriority.low,
          ),
        ],
      );

      final result = await dataSource.getCachedTasks(
        page: 1,
        limit: 2,
        searchQuery: 'design',
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
      );

      expect(result.tasks, hasLength(2));
      expect(result.tasks.map((t) => t.id), ['2', '3']);
      expect(result.page, 1);
      expect(result.totalPages, 1);

      final page2 = await dataSource.getCachedTasks(
        page: 2,
        limit: 1,
        searchQuery: 'design',
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
      );

      expect(page2.tasks, hasLength(1));
      expect(page2.tasks.single.id, '3');
      expect(page2.totalPages, 2);
    });
  });

  group('DashboardLocalDataSourceImpl.cacheTasks', () {
    test('page 1 merges and keeps fresher local task', () async {
      final localFresher = taskModel(
        id: 1,
        title: 'Local fresher',
        updatedAt: futureStamp,
      );
      final localStale = taskModel(
        id: 2,
        title: 'Local stale',
        updatedAt: older,
      );

      when(
        () => taskLocalDataSource.getCachedTaskList(),
      ).thenAnswer((_) async => [localFresher, localStale]);
      when(
        () => taskLocalDataSource.cacheTaskDetails(any()),
      ).thenAnswer((_) async {});
      when(
        () => taskLocalDataSource.cacheTaskList(any()),
      ).thenAnswer((_) async {});

      await dataSource.cacheTasks([
        dashboard.TaskModel(
          id: '1',
          title: 'Remote older',
          description: 'Remote',
          status: 'pending',
          priority: 'medium',
          createdAt: older,
        ),
        dashboard.TaskModel(
          id: '2',
          title: 'Remote newer title',
          description: 'Remote',
          status: 'pending',
          priority: 'medium',
          createdAt: newer,
        ),
      ], page: 1);

      final detailsCalls = verify(
        () => taskLocalDataSource.cacheTaskDetails(captureAny()),
      ).captured.cast<TaskModel>();

      expect(detailsCalls.map((t) => t.id), isNot(contains(1)));
      expect(detailsCalls.map((t) => t.id), contains(2));
      expect(
        detailsCalls.firstWhere((t) => t.id == 2).title,
        'Remote newer title',
      );

      final listArg =
          verify(
                () => taskLocalDataSource.cacheTaskList(captureAny()),
              ).captured.single
              as List<TaskModel>;
      final byId = {for (final task in listArg) task.id: task};
      expect(byId[1]?.title, 'Local fresher');
      expect(byId[2]?.title, 'Remote newer title');
    });

    test('page > 1 upserts each task', () async {
      when(
        () => taskLocalDataSource.upsertCachedTask(any()),
      ).thenAnswer((_) async {});
      when(
        () => taskLocalDataSource.cacheTaskDetails(any()),
      ).thenAnswer((_) async {});

      await dataSource.cacheTasks([
        dashboard.TaskModel(
          id: '10',
          title: 'Page two',
          description: 'More',
          status: 'pending',
          priority: 'low',
          createdAt: older,
        ),
      ], page: 2);

      verify(() => taskLocalDataSource.upsertCachedTask(any())).called(1);
      verify(() => taskLocalDataSource.cacheTaskDetails(any())).called(1);
      verifyNever(() => taskLocalDataSource.getCachedTaskList());
      verifyNever(() => taskLocalDataSource.cacheTaskList(any()));
    });
  });
}
