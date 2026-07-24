import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/features/dashboard/domain/entities/task_entity.dart';
import 'package:team_workspace/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:team_workspace/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:team_workspace/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:team_workspace/features/dashboard/presentation/widgets/pagination_loader.dart';
import 'package:team_workspace/features/dashboard/presentation/widgets/task_card.dart';
import 'package:team_workspace/features/task/presentation/bloc/sync/sync_state.dart';

import '../../../../helpers/test_helper.dart';

void main() {
  late MockDashboardBloc dashboardBloc;
  late MockSyncBloc syncBloc;
  late MockAuthBloc authBloc;

  final task = TaskEntity(
    id: '1',
    title: 'Complete Flutter App',
    description: 'Implement dashboard',
    status: 'pending',
    createdAt: DateTime.parse('2026-01-01'),
  );

  setUpAll(() {
    registerCommonFallbackValues();
  });

  setUp(() {
    dashboardBloc = MockDashboardBloc();
    syncBloc = MockSyncBloc();
    authBloc = MockAuthBloc();

    when(() => syncBloc.state).thenReturn(const SyncSynced());
    when(
      () => syncBloc.stream,
    ).thenAnswer((_) => Stream.value(const SyncSynced()));
  });

  Future<void> pumpDashboard(
    WidgetTester tester, {
    required DashboardState state,
  }) async {
    when(() => dashboardBloc.state).thenReturn(state);
    when(() => dashboardBloc.stream).thenAnswer((_) => Stream.value(state));

    await tester.pumpWidget(
      buildTestApp(
        child: const DashboardPage(),
        dashboardBloc: dashboardBloc,
        syncBloc: syncBloc,
        authBloc: authBloc,
      ),
    );
    await tester.pump();
  }

  group('DashboardPage', () {
    testWidgets('shows filter button instead of logout', (tester) async {
      await pumpDashboard(tester, state: const DashboardLoading());

      expect(
        find.byKey(const ValueKey('dashboard-filter-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('dashboard-logout-button')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('dashboard-search-field')),
        findsOneWidget,
      );
    });

    testWidgets('renders task list with TaskCard', (tester) async {
      await pumpDashboard(
        tester,
        state: DashboardLoaded(
          tasks: [task],
          currentPage: 1,
          hasReachedMax: true,
        ),
      );

      expect(find.byType(TaskCard), findsOneWidget);
      expect(find.text('Complete Flutter App'), findsOneWidget);
      expect(find.text('Implement dashboard'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('shows pagination loader when more pages available', (
      tester,
    ) async {
      await pumpDashboard(
        tester,
        state: DashboardLoaded(
          tasks: [task],
          currentPage: 1,
          hasReachedMax: false,
        ),
      );

      expect(find.byType(PaginationLoader), findsOneWidget);
    });

    testWidgets('shows pagination loader during DashboardLoadingMore', (
      tester,
    ) async {
      await pumpDashboard(
        tester,
        state: DashboardLoadingMore(
          tasks: [task],
          currentPage: 1,
          hasReachedMax: false,
        ),
      );

      expect(find.byType(PaginationLoader), findsOneWidget);
    });

    testWidgets('shows empty state', (tester) async {
      await pumpDashboard(
        tester,
        state: const DashboardLoaded(
          tasks: [],
          currentPage: 1,
          hasReachedMax: true,
        ),
      );

      expect(find.text('No tasks yet.'), findsOneWidget);
    });

    testWidgets('shows error with retry', (tester) async {
      await pumpDashboard(
        tester,
        state: const DashboardError(message: 'Failed to load tasks'),
      );

      expect(find.text('Failed to load tasks'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      verify(() => dashboardBloc.add(const LoadTasks())).called(1);
    });
  });
}
