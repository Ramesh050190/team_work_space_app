import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/core/constants/hive_constants.dart';
import 'package:team_workspace/core/storage/hive_service.dart';
import 'package:team_workspace/features/task/data/datasources/task_local_datasource_impl.dart';
import 'package:team_workspace/features/task/data/models/pending_sync_model.dart';
import 'package:team_workspace/features/task/data/models/task_model.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';

class _MockHiveService extends Mock implements HiveService {}

class _MockTaskDetailsBox extends Mock implements Box<String> {}

class _MockTaskListBox extends Mock implements LazyBox<String> {}

class _MockTasksBox extends Mock implements LazyBox<TaskModel> {}

class _MockPendingOperationsBox extends Mock implements Box<PendingSyncModel> {}

void main() {
  late _MockHiveService hiveService;
  late _MockTaskDetailsBox taskDetailsBox;
  late _MockTaskListBox taskListBox;
  late _MockTasksBox tasksBox;
  late _MockPendingOperationsBox pendingOperationsBox;
  late TaskLocalDataSourceImpl dataSource;

  final task = TaskModel(
    id: 1,
    title: 'Cached task',
    description: 'Details',
    priority: TaskPriority.high,
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

  final pendingOp = PendingSyncModel(
    operationId: 'op-1',
    taskId: 1,
    operationType: PendingOperationType.update,
    payload: const {'completed': true},
    createdAt: DateTime.parse('2026-07-20T08:00:00.000Z'),
  );

  setUpAll(() {
    registerFallbackValue(task);
    registerFallbackValue(pendingOp);
  });

  setUp(() {
    hiveService = _MockHiveService();
    taskDetailsBox = _MockTaskDetailsBox();
    taskListBox = _MockTaskListBox();
    tasksBox = _MockTasksBox();
    pendingOperationsBox = _MockPendingOperationsBox();

    when(() => hiveService.taskDetailsBox).thenReturn(taskDetailsBox);
    when(() => hiveService.taskListBox).thenReturn(taskListBox);
    when(() => hiveService.tasksBox).thenReturn(tasksBox);
    when(
      () => hiveService.pendingOperationsBox,
    ).thenReturn(pendingOperationsBox);

    when(() => taskDetailsBox.put(any(), any())).thenAnswer((_) async {});
    when(() => taskListBox.put(any(), any())).thenAnswer((_) async {});
    when(() => tasksBox.put(any(), any())).thenAnswer((_) async {});
    when(() => pendingOperationsBox.put(any(), any())).thenAnswer((_) async {});
    when(() => taskDetailsBox.delete(any())).thenAnswer((_) async {});
    when(() => tasksBox.delete(any())).thenAnswer((_) async {});
    when(() => pendingOperationsBox.delete(any())).thenAnswer((_) async {});
    when(() => taskDetailsBox.clear()).thenAnswer((_) async => 0);
    when(() => taskListBox.clear()).thenAnswer((_) async => 0);
    when(() => tasksBox.clear()).thenAnswer((_) async => 0);
    when(() => pendingOperationsBox.clear()).thenAnswer((_) async => 0);
    when(() => taskListBox.get(any())).thenAnswer((_) async => null);

    dataSource = TaskLocalDataSourceImpl(hiveService: hiveService);
  });

  group('TaskLocalDataSourceImpl', () {
    test(
      'cacheTaskDetails writes details, typed box, and list upsert',
      () async {
        await dataSource.cacheTaskDetails(task);

        verify(
          () => taskDetailsBox.put('task_details_1', jsonEncode(task.toJson())),
        ).called(greaterThanOrEqualTo(1));
        verify(() => tasksBox.put('1', task)).called(greaterThanOrEqualTo(1));
        verify(
          () => taskListBox.put(
            HiveConstants.taskListCacheKey,
            any(that: contains('"id":1')),
          ),
        ).called(1);
      },
    );

    test('getCachedTaskDetails returns model from json cache', () async {
      when(
        () => taskDetailsBox.get('task_details_1'),
      ).thenReturn(jsonEncode(task.toJson()));

      final result = await dataSource.getCachedTaskDetails(1);

      expect(result, isNotNull);
      expect(result!.id, 1);
      expect(result.title, 'Cached task');
      verifyNever(() => tasksBox.get(any()));
    });

    test('getCachedTaskDetails falls back to tasksBox', () async {
      when(() => taskDetailsBox.get('task_details_1')).thenReturn(null);
      when(() => tasksBox.get('1')).thenAnswer((_) async => task);

      final result = await dataSource.getCachedTaskDetails(1);

      expect(result, same(task));
      verify(() => tasksBox.get('1')).called(1);
    });

    test('getCachedTaskList returns empty when cache missing', () async {
      when(
        () => taskListBox.get(HiveConstants.taskListCacheKey),
      ).thenAnswer((_) async => null);

      final result = await dataSource.getCachedTaskList();

      expect(result, isEmpty);
    });

    test('enqueuePendingOperation stores operation in box', () async {
      await dataSource.enqueuePendingOperation(pendingOp);

      verify(
        () => pendingOperationsBox.put(pendingOp.operationId, pendingOp),
      ).called(1);
    });

    test('getPendingOperations returns values sorted by createdAt', () async {
      final later = pendingOp.copyWith(
        operationId: 'op-2',
        createdAt: DateTime.parse('2026-07-21T08:00:00.000Z'),
      );
      when(() => pendingOperationsBox.values).thenReturn([later, pendingOp]);

      final result = await dataSource.getPendingOperations();

      expect(result.map((op) => op.operationId), ['op-1', 'op-2']);
    });

    test('removePendingOperation deletes by id', () async {
      await dataSource.removePendingOperation('op-1');

      verify(() => pendingOperationsBox.delete('op-1')).called(1);
    });

    test('hasPendingOperationsForTask returns true when matched', () async {
      when(() => pendingOperationsBox.values).thenReturn([pendingOp]);

      expect(await dataSource.hasPendingOperationsForTask(1), isTrue);
      expect(await dataSource.hasPendingOperationsForTask(99), isFalse);
    });

    test('clearAllTaskCache clears all task-related boxes', () async {
      await dataSource.clearAllTaskCache();

      verify(() => taskListBox.clear()).called(1);
      verify(() => taskDetailsBox.clear()).called(1);
      verify(() => tasksBox.clear()).called(1);
      verify(() => pendingOperationsBox.clear()).called(1);
    });
  });
}
