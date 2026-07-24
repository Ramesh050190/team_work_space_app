import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:team_workspace/core/connectivity/connectivity_service.dart';
import 'package:team_workspace/core/constants/message_keys.dart';
import 'package:team_workspace/core/sync/sync_manager.dart';
import 'package:team_workspace/core/usecases/usecase.dart';
import 'package:team_workspace/features/task/data/datasources/task_local_datasource.dart';
import 'package:team_workspace/features/task/domain/usecases/sync_pending_changes_usecase.dart';
import 'package:team_workspace/features/task/presentation/bloc/sync/sync_event.dart';
import 'package:team_workspace/features/task/presentation/bloc/sync/sync_state.dart';

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  SyncBloc({
    required SyncManager syncManager,
    required SyncPendingChangesUseCase syncPendingChangesUseCase,
    required ConnectivityService connectivityService,
    required TaskLocalDataSource localDataSource,
  }) : _syncManager = syncManager,
       _syncPendingChangesUseCase = syncPendingChangesUseCase,
       _connectivityService = connectivityService,
       _localDataSource = localDataSource,
       super(const SyncInitial()) {
    on<SyncStartedListening>(_onStartListening);
    on<ConnectivityChanged>(_onConnectivityChanged);
    on<SyncStarted>(_onSyncStarted);
    on<SyncCompleted>(_onSyncCompleted);
    on<SyncFailed>(_onSyncFailed);
    on<RetrySync>(_onRetrySync);
    on<PendingOperationsUpdated>(_onPendingUpdated);
    on<ResetSyncSession>(_onResetSession);

    _syncManager.onConnectivityChanged = (isConnected) {
      add(ConnectivityChanged(isConnected: isConnected));
    };
  }

  final SyncManager _syncManager;
  final SyncPendingChangesUseCase _syncPendingChangesUseCase;
  final ConnectivityService _connectivityService;
  final TaskLocalDataSource _localDataSource;

  Future<void> _onStartListening(
    SyncStartedListening event,
    Emitter<SyncState> emit,
  ) async {
    _syncManager.start();
    await _emitFromPending(emit);
  }

  Future<void> _onResetSession(
    ResetSyncSession event,
    Emitter<SyncState> emit,
  ) async {
    await _emitFromPending(emit);
  }

  Future<void> _emitFromPending(Emitter<SyncState> emit) async {
    final connected = await _connectivityService.isConnected();
    final pending = await _readPending();
    if (!connected) {
      emit(
        SyncOffline(pendingCount: pending.count, pendingTaskIds: pending.ids),
      );
      return;
    }

    emit(SyncSynced(pendingCount: pending.count, pendingTaskIds: pending.ids));

    if (pending.count > 0) {
      add(const SyncStarted());
    }
  }

  Future<void> _onConnectivityChanged(
    ConnectivityChanged event,
    Emitter<SyncState> emit,
  ) async {
    final pending = await _readPending();
    if (!event.isConnected) {
      emit(
        SyncOffline(pendingCount: pending.count, pendingTaskIds: pending.ids),
      );
      return;
    }

    if (pending.count > 0) {
      add(const SyncStarted());
    } else {
      emit(
        const SyncSynced(
          pendingCount: 0,
          pendingTaskIds: {},
          message: MessageKeys.backOnline,
        ),
      );
    }
  }

  Future<void> _onSyncStarted(
    SyncStarted event,
    Emitter<SyncState> emit,
  ) async {
    final pending = await _readPending();
    emit(SyncSyncing(pendingCount: pending.count, pendingTaskIds: pending.ids));

    final result = await _syncPendingChangesUseCase(const NoParams());
    await result.fold(
      (failure) async {
        final latest = await _readPending();
        emit(
          SyncFailure(
            message: failure.message,
            pendingCount: latest.count,
            pendingTaskIds: latest.ids,
          ),
        );
      },
      (syncResult) async {
        final latest = await _readPending();
        if (syncResult.hasFailures && latest.count > 0) {
          emit(
            SyncFailure(
              message: MessageKeys.syncedPartial(
                synced: syncResult.syncedCount,
                failed: syncResult.failedCount,
              ),
              pendingCount: latest.count,
              pendingTaskIds: latest.ids,
            ),
          );
        } else {
          emit(
            SyncSynced(
              pendingCount: latest.count,
              pendingTaskIds: latest.ids,
              message: syncResult.syncedCount > 0
                  ? MessageKeys.syncedCount(syncResult.syncedCount)
                  : null,
            ),
          );
        }
      },
    );
  }

  Future<void> _onSyncCompleted(
    SyncCompleted event,
    Emitter<SyncState> emit,
  ) async {
    final pending = await _readPending();
    emit(
      SyncSynced(
        pendingCount: pending.count,
        pendingTaskIds: pending.ids,
        message: event.syncedCount > 0
            ? MessageKeys.syncedCount(event.syncedCount)
            : null,
      ),
    );
  }

  Future<void> _onSyncFailed(SyncFailed event, Emitter<SyncState> emit) async {
    final pending = await _readPending();
    emit(
      SyncFailure(
        message: event.message,
        pendingCount: pending.count,
        pendingTaskIds: pending.ids,
      ),
    );
  }

  Future<void> _onRetrySync(RetrySync event, Emitter<SyncState> emit) async {
    add(const SyncStarted());
  }

  void _onPendingUpdated(
    PendingOperationsUpdated event,
    Emitter<SyncState> emit,
  ) {
    final current = state;
    if (current is SyncOffline || current.isOffline) {
      emit(
        SyncOffline(
          pendingCount: event.pendingCount,
          pendingTaskIds: event.pendingTaskIds,
        ),
      );
      return;
    }
    if (current is SyncSyncing) {
      emit(
        SyncSyncing(
          pendingCount: event.pendingCount,
          pendingTaskIds: event.pendingTaskIds,
        ),
      );
      return;
    }
    emit(
      SyncSynced(
        pendingCount: event.pendingCount,
        pendingTaskIds: event.pendingTaskIds,
      ),
    );
  }

  /// Call after local mutations so UI badges stay fresh.
  Future<void> refreshPending() async {
    final pending = await _readPending();
    add(
      PendingOperationsUpdated(
        pendingCount: pending.count,
        pendingTaskIds: pending.ids,
      ),
    );
  }

  Future<({int count, Set<int> ids})> _readPending() async {
    final ops = await _localDataSource.getPendingOperations();
    return (
      count: ops.length,
      ids: ops.map((operation) => operation.taskId).toSet(),
    );
  }

  @override
  Future<void> close() async {
    await _syncManager.stop();
    return super.close();
  }
}
