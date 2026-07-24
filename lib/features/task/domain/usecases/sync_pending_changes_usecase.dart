import 'package:dartz/dartz.dart';
import 'package:team_workspace/core/errors/failure.dart';
import 'package:team_workspace/core/sync/sync_manager.dart';
import 'package:team_workspace/core/usecases/usecase.dart';

class SyncPendingChangesUseCase implements UseCase<SyncResult, NoParams> {
  SyncPendingChangesUseCase(this._syncManager);

  final SyncManager _syncManager;

  @override
  Future<Either<Failure, SyncResult>> call(NoParams params) {
    return _syncManager.syncPendingChanges();
  }
}
