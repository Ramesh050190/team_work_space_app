import 'package:dartz/dartz.dart' hide Task;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/core/connectivity/connectivity_service.dart';
import 'package:team_workspace/core/exceptions/server_exception.dart';
import 'package:team_workspace/core/logger/app_logger.dart';
import 'package:team_workspace/core/sync/sync_manager.dart';
import 'package:team_workspace/features/task/data/datasources/task_local_datasource.dart';
import 'package:team_workspace/features/task/data/datasources/task_remote_datasource.dart';
import 'package:team_workspace/features/task/data/models/pending_sync_model.dart';
import 'package:team_workspace/features/task/data/models/task_model.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';

class _MockRemote extends Mock implements TaskRemoteDataSource {}

class _MockLocal extends Mock implements TaskLocalDataSource {}

class _MockConnectivity extends Mock implements ConnectivityService {}

class _MockLogger extends Mock implements AppLogger {}

void main() {
  late _MockRemote remote;
  late _MockLocal local;
  late _MockConnectivity connectivity;
  late _MockLogger logger;
  late SyncManager syncManager;

  final task = TaskModel(
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
    registerFallbackValue(task);
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
    remote = _MockRemote();
    local = _MockLocal();
    connectivity = _MockConnectivity();
    logger = _MockLogger();
    syncManager = SyncManager(
      remoteDataSource: remote,
      localDataSource: local,
      connectivityService: connectivity,
      logger: logger,
    );
  });

  test('returns SyncFailure when offline', () async {
    when(() => connectivity.isConnected()).thenAnswer((_) async => false);

    final result = await syncManager.syncPendingChanges();

    expect(result.isLeft(), isTrue);
  });

  test('syncs pending status change and removes operation', () async {
    final pending = PendingSyncModel(
      operationId: 'op-1',
      taskId: 1,
      operationType: PendingOperationType.statusChange,
      payload: const {'completed': true},
      createdAt: DateTime.parse('2026-07-20T08:00:00.000Z'),
    );
    final updated = task.copyWith(
      completed: true,
      status: TaskStatus.completed,
    );

    when(() => connectivity.isConnected()).thenAnswer((_) async => true);
    when(() => local.getPendingOperations()).thenAnswer((_) async => [pending]);
    when(
      () => remote.updateTaskStatus(id: 1, completed: true),
    ).thenAnswer((_) async => updated);
    when(() => local.cacheTaskDetails(updated)).thenAnswer((_) async {});
    when(() => local.removePendingOperation('op-1')).thenAnswer((_) async {});

    final result = await syncManager.syncPendingChanges();

    expect(result, isA<Right>());
    result.fold((_) => fail('expected success'), (syncResult) {
      expect(syncResult.syncedCount, 1);
      expect(syncResult.failedCount, 0);
    });
    verify(() => local.removePendingOperation('op-1')).called(1);
  });

  test('remaps local create id onto later update and status ops', () async {
    const localId = -42;
    final localTask = task.copyWith(id: localId);
    final created = task.copyWith(id: 99);
    final updated = created.copyWith(title: 'Updated offline');

    final createOp = PendingSyncModel(
      operationId: 'create-op',
      taskId: localId,
      operationType: PendingOperationType.create,
      payload: localTask.toJson(),
      createdAt: DateTime.parse('2026-07-20T08:00:00.000Z'),
    );
    final updateOp = PendingSyncModel(
      operationId: 'update-op',
      taskId: localId,
      operationType: PendingOperationType.update,
      payload: localTask.copyWith(title: 'Updated offline').toJson(),
      createdAt: DateTime.parse('2026-07-20T08:01:00.000Z'),
    );
    final statusOp = PendingSyncModel(
      operationId: 'status-op',
      taskId: localId,
      operationType: PendingOperationType.statusChange,
      payload: const {'completed': true},
      createdAt: DateTime.parse('2026-07-20T08:02:00.000Z'),
    );

    when(() => connectivity.isConnected()).thenAnswer((_) async => true);
    when(
      () => local.getPendingOperations(),
    ).thenAnswer((_) async => [createOp, updateOp, statusOp]);
    when(() => remote.createTask(any())).thenAnswer((_) async => created);
    when(
      () => local.replaceCachedTaskId(localId: localId, serverTask: created),
    ).thenAnswer((_) async {});
    when(() => remote.getTaskDetails(99)).thenAnswer((_) async => created);
    when(() => remote.updateTask(any())).thenAnswer((_) async => updated);
    when(() => local.cacheTaskDetails(any())).thenAnswer((_) async {});
    when(() => remote.updateTaskStatus(id: 99, completed: true)).thenAnswer(
      (_) async =>
          updated.copyWith(completed: true, status: TaskStatus.completed),
    );
    when(() => local.removePendingOperation(any())).thenAnswer((_) async {});

    final result = await syncManager.syncPendingChanges();

    expect(result.isRight(), isTrue);
    result.fold((_) => fail('expected success'), (syncResult) {
      expect(syncResult.syncedCount, 3);
      expect(syncResult.failedCount, 0);
    });

    verify(() => remote.createTask(any())).called(1);
    final capturedUpdate =
        verify(() => remote.updateTask(captureAny())).captured.single
            as TaskModel;
    expect(capturedUpdate.id, 99);
    verify(() => remote.updateTaskStatus(id: 99, completed: true)).called(1);
    verifyNever(
      () => remote.updateTaskStatus(
        id: localId,
        completed: any(named: 'completed'),
      ),
    );
  });

  test(
    'drops pending op on permanent 404 instead of retrying forever',
    () async {
      final pending = PendingSyncModel(
        operationId: 'op-missing',
        taskId: 999,
        operationType: PendingOperationType.statusChange,
        payload: const {'completed': true},
        createdAt: DateTime.parse('2026-07-20T08:00:00.000Z'),
      );

      when(() => connectivity.isConnected()).thenAnswer((_) async => true);
      when(
        () => local.getPendingOperations(),
      ).thenAnswer((_) async => [pending]);
      when(() => remote.updateTaskStatus(id: 999, completed: true)).thenThrow(
        const ServerException(message: 'Task not found', statusCode: 404),
      );
      when(
        () => local.removePendingOperation('op-missing'),
      ).thenAnswer((_) async {});

      final result = await syncManager.syncPendingChanges();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected Right'), (syncResult) {
        expect(syncResult.failedCount, 1);
        expect(syncResult.syncedCount, 0);
      });
      verify(() => local.removePendingOperation('op-missing')).called(1);
      verifyNever(() => local.updatePendingOperation(any()));
    },
  );
}
