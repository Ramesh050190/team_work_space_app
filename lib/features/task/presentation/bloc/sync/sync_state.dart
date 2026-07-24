import 'package:equatable/equatable.dart';

sealed class SyncState extends Equatable {
  const SyncState();

  bool get isOffline => this is SyncOffline;
  bool get isSyncing => this is SyncSyncing;
  int get pendingCount => switch (this) {
    SyncOffline(:final pendingCount) => pendingCount,
    SyncSyncing(:final pendingCount) => pendingCount,
    SyncSynced(:final pendingCount) => pendingCount,
    SyncFailure(:final pendingCount) => pendingCount,
    _ => 0,
  };

  Set<int> get pendingTaskIds => switch (this) {
    SyncOffline(:final pendingTaskIds) => pendingTaskIds,
    SyncSyncing(:final pendingTaskIds) => pendingTaskIds,
    SyncSynced(:final pendingTaskIds) => pendingTaskIds,
    SyncFailure(:final pendingTaskIds) => pendingTaskIds,
    _ => const <int>{},
  };

  @override
  List<Object?> get props => [];
}

class SyncInitial extends SyncState {
  const SyncInitial();
}

class SyncOffline extends SyncState {
  const SyncOffline({this.pendingCount = 0, this.pendingTaskIds = const {}});

  @override
  final int pendingCount;
  @override
  final Set<int> pendingTaskIds;

  @override
  List<Object?> get props => [pendingCount, pendingTaskIds];
}

class SyncSyncing extends SyncState {
  const SyncSyncing({this.pendingCount = 0, this.pendingTaskIds = const {}});

  @override
  final int pendingCount;
  @override
  final Set<int> pendingTaskIds;

  @override
  List<Object?> get props => [pendingCount, pendingTaskIds];
}

class SyncSynced extends SyncState {
  const SyncSynced({
    this.pendingCount = 0,
    this.pendingTaskIds = const {},
    this.message,
  });

  @override
  final int pendingCount;
  @override
  final Set<int> pendingTaskIds;
  final String? message;

  @override
  List<Object?> get props => [pendingCount, pendingTaskIds, message];
}

class SyncFailure extends SyncState {
  const SyncFailure({
    required this.message,
    this.pendingCount = 0,
    this.pendingTaskIds = const {},
  });

  final String message;
  @override
  final int pendingCount;
  @override
  final Set<int> pendingTaskIds;

  @override
  List<Object?> get props => [message, pendingCount, pendingTaskIds];
}
