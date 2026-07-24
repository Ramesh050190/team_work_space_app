import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/core/constants/hive_constants.dart';
import 'package:team_workspace/core/exceptions/cache_exception.dart';
import 'package:team_workspace/core/storage/hive_service.dart';
import 'package:team_workspace/features/task/data/datasources/task_local_datasource_impl.dart';
import 'package:team_workspace/features/task/data/models/pending_sync_model.dart';
import 'package:team_workspace/features/task/data/models/task_model.dart';
import 'package:team_workspace/features/task/data/models/task_model_adapter.dart';

class MockHiveService extends Mock implements HiveService {}

void main() {
  late Directory tempDir;
  late Box<String> taskDetailsBox;
  late LazyBox<String> taskListBox;
  late Box<PendingSyncModel> pendingBox;
  late LazyBox<TaskModel> tasksBox;
  late MockHiveService hiveService;
  late TaskLocalDataSourceImpl dataSource;

  TaskModel sampleTask({int id = 1, String title = 'Task'}) {
    return TaskModel.fromJson({
      'id': id,
      'title': title,
      'description': 'Description here',
      'priority': 'medium',
      'status': 'pending',
      'dueDate': '2026-07-25T00:00:00.000Z',
      'assignedUser': {
        'id': 'u1',
        'name': 'Alex',
        'email': 'alex@example.com',
      },
      'createdAt': '2026-07-20T08:00:00.000Z',
      'updatedAt': '2026-07-20T08:00:00.000Z',
      'completed': false,
    });
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('task_local_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TaskModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(PendingSyncModelAdapter());
    }

    taskDetailsBox = await Hive.openBox<String>(HiveConstants.taskDetailsBox);
    taskListBox = await Hive.openLazyBox<String>(HiveConstants.taskListBox);
    pendingBox = await Hive.openBox<PendingSyncModel>(
      HiveConstants.pendingOperationsBox,
    );
    tasksBox = await Hive.openLazyBox<TaskModel>(HiveConstants.tasksBox);

    hiveService = MockHiveService();
    when(() => hiveService.taskDetailsBox).thenReturn(taskDetailsBox);
    when(() => hiveService.taskListBox).thenReturn(taskListBox);
    when(() => hiveService.pendingOperationsBox).thenReturn(pendingBox);
    when(() => hiveService.tasksBox).thenReturn(tasksBox);

    dataSource = TaskLocalDataSourceImpl(hiveService: hiveService);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('TaskLocalDataSourceImpl', () {
    test('cache and get task details', () async {
      final task = sampleTask();
      await dataSource.cacheTaskDetails(task);

      final cached = await dataSource.getCachedTaskDetails(1);
      expect(cached?.title, 'Task');
      expect(await tasksBox.get('1'), isNotNull);
    });

    test('getCachedTaskDetails falls back to tasksBox', () async {
      final task = sampleTask(id: 9);
      await tasksBox.put('9', task);

      final cached = await dataSource.getCachedTaskDetails(9);
      expect(cached?.id, 9);
    });

    test('cacheTaskList / getCachedTaskList / empty', () async {
      expect(await dataSource.getCachedTaskList(), isEmpty);

      await dataSource.cacheTaskList([sampleTask(), sampleTask(id: 2)]);
      final list = await dataSource.getCachedTaskList();
      expect(list, hasLength(2));
    });

    test('upsert inserts then replaces', () async {
      await dataSource.upsertCachedTask(sampleTask(title: 'First'));
      await dataSource.upsertCachedTask(sampleTask(title: 'Updated'));

      final list = await dataSource.getCachedTaskList();
      expect(list, hasLength(1));
      expect(list.first.title, 'Updated');
    });

    test('removeCachedTask and clearTaskDetails', () async {
      await dataSource.cacheTaskDetails(sampleTask());
      await dataSource.removeCachedTask(1);

      expect(await dataSource.getCachedTaskDetails(1), isNull);
      expect(await dataSource.getCachedTaskList(), isEmpty);
    });

    test('pending enqueue get remove update and helpers', () async {
      final older = PendingSyncModel(
        operationId: 'op-1',
        taskId: 1,
        operationType: PendingOperationType.update,
        payload: const {'id': 1},
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final newer = PendingSyncModel(
        operationId: 'op-2',
        taskId: 2,
        operationType: PendingOperationType.create,
        payload: const {'id': 2},
        createdAt: DateTime.utc(2026, 1, 2),
      );

      await dataSource.enqueuePendingOperation(newer);
      await dataSource.enqueuePendingOperation(older);

      final pending = await dataSource.getPendingOperations();
      expect(pending.map((e) => e.operationId), ['op-1', 'op-2']);
      expect(await dataSource.hasPendingOperationsForTask(1), isTrue);
      expect(await dataSource.getPendingTaskIds(), {1, 2});

      await dataSource.updatePendingOperation(older.copyWith(retryCount: 2));
      expect((await dataSource.getPendingOperations()).first.retryCount, 2);

      await dataSource.removePendingOperation('op-1');
      expect(await dataSource.hasPendingOperationsForTask(1), isFalse);
    });

    test('remapPendingTaskId rewrites payload and skips create', () async {
      await dataSource.enqueuePendingOperation(
        PendingSyncModel(
          operationId: 'upd',
          taskId: -5,
          operationType: PendingOperationType.update,
          payload: const {'id': -5, 'title': 'X'},
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await dataSource.enqueuePendingOperation(
        PendingSyncModel(
          operationId: 'crt',
          taskId: -5,
          operationType: PendingOperationType.create,
          payload: const {'id': -5},
          createdAt: DateTime.utc(2026, 1, 2),
        ),
      );

      await dataSource.remapPendingTaskId(localId: -5, serverId: 99);
      await dataSource.remapPendingTaskId(localId: 99, serverId: 99);

      final pending = await dataSource.getPendingOperations();
      final update = pending.firstWhere((e) => e.operationId == 'upd');
      expect(update.taskId, 99);
      expect(update.payload['id'], 99);
      expect(
        pending.firstWhere((e) => e.operationId == 'crt').taskId,
        -5,
      );
    });

    test('replaceCachedTaskId swaps local for server', () async {
      await dataSource.cacheTaskDetails(sampleTask(id: -1, title: 'Local'));
      await dataSource.enqueuePendingOperation(
        PendingSyncModel(
          operationId: 'u1',
          taskId: -1,
          operationType: PendingOperationType.statusChange,
          payload: const {'id': -1},
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );

      await dataSource.replaceCachedTaskId(
        localId: -1,
        serverTask: sampleTask(id: 50, title: 'Server'),
      );

      expect(await dataSource.getCachedTaskDetails(-1), isNull);
      expect((await dataSource.getCachedTaskDetails(50))?.title, 'Server');
      expect(
        (await dataSource.getPendingOperations()).first.taskId,
        50,
      );
    });

    test('clearAllTaskCache clears boxes', () async {
      await dataSource.cacheTaskDetails(sampleTask());
      await dataSource.enqueuePendingOperation(
        PendingSyncModel(
          operationId: 'x',
          taskId: 1,
          operationType: PendingOperationType.delete,
          payload: const {},
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );

      await dataSource.clearAllTaskCache();

      expect(taskDetailsBox.isEmpty, isTrue);
      expect(pendingBox.isEmpty, isTrue);
      expect(await dataSource.getCachedTaskList(), isEmpty);
    });

    test('wraps failures as CacheException', () async {
      when(() => hiveService.taskDetailsBox).thenThrow(Exception('down'));
      expect(
        () => dataSource.getCachedTaskDetails(1),
        throwsA(isA<CacheException>()),
      );
    });

    test('getCachedTaskList throws CacheException on bad json', () async {
      await taskListBox.put(HiveConstants.taskListCacheKey, 'not-json');
      expect(
        () => dataSource.getCachedTaskList(),
        throwsA(isA<CacheException>()),
      );
    });

    test('getCachedTaskDetails throws on corrupt json', () async {
      await taskDetailsBox.put('task_details_1', '{bad');
      expect(
        () => dataSource.getCachedTaskDetails(1),
        throwsA(isA<CacheException>()),
      );
    });
  });
}
