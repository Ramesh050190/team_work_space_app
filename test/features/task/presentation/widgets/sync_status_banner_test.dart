import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/features/task/presentation/bloc/sync/sync_bloc.dart';
import 'package:team_workspace/features/task/presentation/bloc/sync/sync_event.dart';
import 'package:team_workspace/features/task/presentation/bloc/sync/sync_state.dart';
import 'package:team_workspace/features/task/presentation/widgets/sync_status_banner.dart';

import '../../../../helpers/mocks.dart';
import '../../../../helpers/pump_with_l10n.dart';

void main() {
  late MockSyncBloc syncBloc;

  setUpAll(() {
    registerFallbackValue(const RetrySync());
  });

  setUp(() {
    syncBloc = MockSyncBloc();
  });

  Widget pumpBanner(SyncState state) {
    when(() => syncBloc.state).thenReturn(state);
    whenListen(syncBloc, Stream<SyncState>.empty(), initialState: state);
    return pumpWithL10n(
      BlocProvider<SyncBloc>.value(
        value: syncBloc,
        child: const Scaffold(body: SyncStatusBanner()),
      ),
    );
  }

  testWidgets('shows offline banner', (tester) async {
    await tester.pumpWidget(
      pumpBanner(const SyncOffline(pendingCount: 0, pendingTaskIds: {})),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
  });

  testWidgets('shows offline pending count', (tester) async {
    await tester.pumpWidget(
      pumpBanner(const SyncOffline(pendingCount: 2, pendingTaskIds: {1, 2})),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Offline'), findsOneWidget);
  });

  testWidgets('shows syncing indicator', (tester) async {
    await tester.pumpWidget(
      pumpBanner(const SyncSyncing(pendingCount: 1, pendingTaskIds: {1})),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('failure banner retries', (tester) async {
    await tester.pumpWidget(
      pumpBanner(
        const SyncFailure(
          message: 'sync failed',
          pendingCount: 1,
          pendingTaskIds: {1},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Retry'));
    await tester.pump();
    verify(() => syncBloc.add(const RetrySync())).called(1);
  });

  testWidgets('synced with pending message shows upload banner', (tester) async {
    await tester.pumpWidget(
      pumpBanner(
        const SyncSynced(
          pendingCount: 3,
          pendingTaskIds: {1, 2, 3},
          message: 'waiting',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
  });

  testWidgets('idle synced hides banner', (tester) async {
    await tester.pumpWidget(pumpBanner(const SyncSynced()));
    await tester.pumpAndSettle();
    expect(find.byType(SizedBox), findsWidgets);
  });
}
