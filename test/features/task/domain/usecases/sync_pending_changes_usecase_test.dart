import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/core/errors/sync_failure.dart';
import 'package:team_workspace/core/sync/sync_manager.dart';
import 'package:team_workspace/core/usecases/usecase.dart';
import 'package:team_workspace/features/task/domain/usecases/sync_pending_changes_usecase.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockSyncManager syncManager;
  late SyncPendingChangesUseCase useCase;

  setUp(() {
    syncManager = MockSyncManager();
    useCase = SyncPendingChangesUseCase(syncManager);
  });

  group('SyncPendingChangesUseCase', () {
    test('returns SyncResult when sync succeeds', () async {
      const result = SyncResult(
        syncedCount: 2,
        failedCount: 0,
        conflictCount: 0,
      );
      when(
        () => syncManager.syncPendingChanges(),
      ).thenAnswer((_) async => const Right(result));

      final outcome = await useCase(const NoParams());

      expect(outcome, const Right(result));
      verify(() => syncManager.syncPendingChanges()).called(1);
    });

    test('returns SyncFailure when sync fails', () async {
      when(() => syncManager.syncPendingChanges()).thenAnswer(
        (_) async =>
            const Left(SyncFailure(message: 'Cannot sync while offline.')),
      );

      final outcome = await useCase(const NoParams());

      expect(
        outcome,
        const Left(SyncFailure(message: 'Cannot sync while offline.')),
      );
    });
  });
}
