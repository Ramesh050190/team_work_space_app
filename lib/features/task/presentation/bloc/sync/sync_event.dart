import 'package:equatable/equatable.dart';

sealed class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

class SyncStartedListening extends SyncEvent {
  const SyncStartedListening();
}

/// Clears pending badges after logout / account switch.
class ResetSyncSession extends SyncEvent {
  const ResetSyncSession();
}

class ConnectivityChanged extends SyncEvent {
  const ConnectivityChanged({required this.isConnected});

  final bool isConnected;

  @override
  List<Object?> get props => [isConnected];
}

class SyncStarted extends SyncEvent {
  const SyncStarted();
}

class SyncCompleted extends SyncEvent {
  const SyncCompleted({
    required this.syncedCount,
    required this.failedCount,
    required this.conflictCount,
  });

  final int syncedCount;
  final int failedCount;
  final int conflictCount;

  @override
  List<Object?> get props => [syncedCount, failedCount, conflictCount];
}

class SyncFailed extends SyncEvent {
  const SyncFailed({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

class RetrySync extends SyncEvent {
  const RetrySync();
}

class PendingOperationsUpdated extends SyncEvent {
  const PendingOperationsUpdated({
    required this.pendingCount,
    required this.pendingTaskIds,
  });

  final int pendingCount;
  final Set<int> pendingTaskIds;

  @override
  List<Object?> get props => [pendingCount, pendingTaskIds];
}
