import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/core/connectivity/connectivity_service.dart';
import 'package:team_workspace/core/constants/message_keys.dart';
import 'package:team_workspace/core/errors/server_failure.dart';
import 'package:team_workspace/core/sync/sync_manager.dart';
import 'package:team_workspace/core/usecases/usecase.dart';
import 'package:team_workspace/features/task/data/datasources/task_local_datasource.dart';
import 'package:team_workspace/features/task/data/models/pending_sync_model.dart';
import 'package:team_workspace/features/task/domain/usecases/sync_pending_changes_usecase.dart';
import 'package:team_workspace/features/task/presentation/bloc/sync/sync_bloc.dart';
import 'package:team_workspace/features/task/presentation/bloc/sync/sync_event.dart';
import 'package:team_workspace/features/task/presentation/bloc/sync/sync_state.dart';

class MockSyncManager extends Mock implements SyncManager {}

class MockSyncPendingChangesUseCase extends Mock
    implements SyncPendingChangesUseCase {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockTaskLocalDataSource extends Mock implements TaskLocalDataSource {}

void main() {
  late MockSyncManager syncManager;
  late MockSyncPendingChangesUseCase syncUseCase;
  late MockConnectivityService connectivity;
  late MockTaskLocalDataSource local;

  PendingSyncModel pendingOp(int taskId) => PendingSyncModel(
        operationId: 'op-$taskId',
        taskId: taskId,
        operationType: PendingOperationType.update,
        payload: {'id': taskId},
        createdAt: DateTime.utc(2026, 1, 1),
      );

  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    syncManager = MockSyncManager();
    syncUseCase = MockSyncPendingChangesUseCase();
    connectivity = MockConnectivityService();
    local = MockTaskLocalDataSource();
    when(() => syncManager.start()).thenReturn(null);
    when(() => syncManager.stop()).thenAnswer((_) async {});
    when(() => local.getPendingOperations()).thenAnswer((_) async => []);
  });

  SyncBloc buildBloc() => SyncBloc(
        syncManager: syncManager,
        syncPendingChangesUseCase: syncUseCase,
        connectivityService: connectivity,
        localDataSource: local,
      );

  group('SyncBloc', () {
    blocTest<SyncBloc, SyncState>(
      'SyncStartedListening offline emits SyncOffline',
      build: () {
        when(() => connectivity.isConnected()).thenAnswer((_) async => false);
        when(() => local.getPendingOperations())
            .thenAnswer((_) async => [pendingOp(1)]);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const SyncStartedListening()),
      expect: () => [
        isA<SyncOffline>()
            .having((s) => s.pendingCount, 'pendingCount', 1)
            .having((s) => s.pendingTaskIds, 'ids', {1}),
      ],
      verify: (_) {
        verify(() => syncManager.start()).called(1);
      },
    );

    blocTest<SyncBloc, SyncState>(
      'online with pending auto-starts sync',
      build: () {
        when(() => connectivity.isConnected()).thenAnswer((_) async => true);
        when(() => local.getPendingOperations())
            .thenAnswer((_) async => [pendingOp(3)]);
        when(() => syncUseCase(any())).thenAnswer(
          (_) async => const Right(
            SyncResult(syncedCount: 1, failedCount: 0, conflictCount: 0),
          ),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const SyncStartedListening()),
      expect: () => [
        isA<SyncSynced>().having((s) => s.pendingCount, 'pending', 1),
        isA<SyncSyncing>(),
        isA<SyncSynced>(),
      ],
    );

    blocTest<SyncBloc, SyncState>(
      'ConnectivityChanged offline emits SyncOffline',
      build: () {
        when(() => local.getPendingOperations())
            .thenAnswer((_) async => [pendingOp(2)]);
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const ConnectivityChanged(isConnected: false)),
      expect: () => [isA<SyncOffline>()],
    );

    blocTest<SyncBloc, SyncState>(
      'ConnectivityChanged online with no pending emits backOnline',
      build: () {
        when(() => local.getPendingOperations()).thenAnswer((_) async => []);
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const ConnectivityChanged(isConnected: true)),
      expect: () => [
        isA<SyncSynced>().having(
          (s) => s.message,
          'message',
          MessageKeys.backOnline,
        ),
      ],
    );

    blocTest<SyncBloc, SyncState>(
      'SyncStarted failure emits SyncFailure',
      build: () {
        when(() => local.getPendingOperations())
            .thenAnswer((_) async => [pendingOp(1)]);
        when(() => syncUseCase(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'sync failed')),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const SyncStarted()),
      expect: () => [
        isA<SyncSyncing>(),
        isA<SyncFailure>().having((s) => s.message, 'msg', 'sync failed'),
      ],
    );

    blocTest<SyncBloc, SyncState>(
      'partial sync failures emit SyncFailure',
      build: () {
        when(() => local.getPendingOperations())
            .thenAnswer((_) async => [pendingOp(1)]);
        when(() => syncUseCase(any())).thenAnswer(
          (_) async => const Right(
            SyncResult(syncedCount: 1, failedCount: 1, conflictCount: 0),
          ),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const SyncStarted()),
      expect: () => [
        isA<SyncSyncing>(),
        isA<SyncFailure>(),
      ],
    );

    blocTest<SyncBloc, SyncState>(
      'RetrySync triggers SyncStarted',
      build: () {
        when(() => local.getPendingOperations()).thenAnswer((_) async => []);
        when(() => syncUseCase(any())).thenAnswer(
          (_) async => const Right(
            SyncResult(syncedCount: 0, failedCount: 0, conflictCount: 0),
          ),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const RetrySync()),
      expect: () => [
        isA<SyncSyncing>(),
        isA<SyncSynced>(),
      ],
    );

    blocTest<SyncBloc, SyncState>(
      'SyncCompleted and SyncFailed update state',
      build: () {
        when(() => local.getPendingOperations()).thenAnswer((_) async => []);
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(
          const SyncCompleted(
            syncedCount: 2,
            failedCount: 0,
            conflictCount: 0,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SyncFailed(message: 'nope'));
      },
      expect: () => [
        isA<SyncSynced>().having(
          (s) => s.message,
          'message',
          MessageKeys.syncedCount(2),
        ),
        isA<SyncFailure>().having((s) => s.message, 'msg', 'nope'),
      ],
    );

    blocTest<SyncBloc, SyncState>(
      'PendingOperationsUpdated while offline stays offline',
      build: buildBloc,
      seed: () => const SyncOffline(pendingCount: 0, pendingTaskIds: {}),
      act: (bloc) => bloc.add(
        const PendingOperationsUpdated(pendingCount: 2, pendingTaskIds: {1, 2}),
      ),
      expect: () => [
        isA<SyncOffline>().having((s) => s.pendingCount, 'count', 2),
      ],
    );

    blocTest<SyncBloc, SyncState>(
      'ResetSyncSession re-emits from pending',
      build: () {
        when(() => connectivity.isConnected()).thenAnswer((_) async => true);
        when(() => local.getPendingOperations()).thenAnswer((_) async => []);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ResetSyncSession()),
      expect: () => [isA<SyncSynced>()],
    );
  });
}
