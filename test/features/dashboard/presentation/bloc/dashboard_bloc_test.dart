import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/core/errors/failure.dart';
import 'package:team_workspace/core/errors/server_failure.dart';
import 'package:team_workspace/features/dashboard/domain/entities/paginated_tasks_page.dart';
import 'package:team_workspace/features/dashboard/domain/entities/task_entity.dart';
import 'package:team_workspace/features/dashboard/domain/usecases/get_tasks_usecase.dart';
import 'package:team_workspace/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:team_workspace/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:team_workspace/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';

class _MockGetTasksUseCase extends Mock implements GetTasksUseCase {}

void main() {
  late _MockGetTasksUseCase getTasksUseCase;

  final task = TaskEntity(
    id: '1',
    title: 'Complete Flutter App',
    description: 'Implement dashboard',
    status: 'pending',
    createdAt: DateTime.parse('2026-01-01'),
  );

  final cachedTask = TaskEntity(
    id: '1',
    title: 'Cached Flutter App',
    description: 'From Hive',
    status: 'pending',
    createdAt: DateTime.parse('2026-01-01'),
  );

  final taskPage2 = TaskEntity(
    id: '2',
    title: 'Write tests',
    description: 'Cover pagination',
    status: 'in_progress',
    createdAt: DateTime.parse('2026-01-02'),
  );

  setUpAll(() {
    registerFallbackValue(const GetTasksParams());
  });

  setUp(() {
    getTasksUseCase = _MockGetTasksUseCase();
  });

  DashboardBloc buildBloc() => DashboardBloc(getTasksUseCase: getTasksUseCase);

  /// Default: empty cache, then network response based on [network].
  void stubEmptyCacheThen(
    Future<Either<Failure, PaginatedTasksPage>> Function(Invocation) network,
  ) {
    when(() => getTasksUseCase(any())).thenAnswer((invocation) async {
      final params = invocation.positionalArguments.first as GetTasksParams;
      if (params.cacheOnly) {
        return const Right(
          PaginatedTasksPage(tasks: [], page: 1, totalPages: 1),
        );
      }
      return network(invocation);
    });
  }

  group('DashboardBloc pagination', () {
    blocTest<DashboardBloc, DashboardState>(
      'LoadTasks emits Loading then Loaded when cache empty',
      build: buildBloc,
      setUp: () {
        stubEmptyCacheThen(
          (_) async =>
              Right(PaginatedTasksPage(tasks: [task], page: 1, totalPages: 2)),
        );
      },
      act: (bloc) => bloc.add(const LoadTasks()),
      expect: () => [
        const DashboardLoading(),
        isA<DashboardLoaded>()
            .having((s) => s.tasks.length, 'tasks', 1)
            .having((s) => s.currentPage, 'page', 1)
            .having((s) => s.hasReachedMax, 'max', isFalse)
            .having((s) => s.isFromCache, 'fromCache', isFalse),
      ],
    );

    blocTest<DashboardBloc, DashboardState>(
      'LoadTasks paints cache first then refreshes from network',
      build: buildBloc,
      setUp: () {
        var call = 0;
        when(() => getTasksUseCase(any())).thenAnswer((invocation) async {
          call++;
          final params = invocation.positionalArguments.first as GetTasksParams;
          if (params.cacheOnly || call == 1) {
            return Right(
              PaginatedTasksPage(tasks: [cachedTask], page: 1, totalPages: 1),
            );
          }
          return Right(
            PaginatedTasksPage(tasks: [task], page: 1, totalPages: 2),
          );
        });
      },
      act: (bloc) => bloc.add(const LoadTasks()),
      expect: () => [
        isA<DashboardLoaded>()
            .having((s) => s.tasks.single.title, 'title', 'Cached Flutter App')
            .having((s) => s.isFromCache, 'fromCache', isTrue),
        isA<DashboardLoaded>()
            .having(
              (s) => s.tasks.single.title,
              'title',
              'Complete Flutter App',
            )
            .having((s) => s.isFromCache, 'fromCache', isFalse)
            .having((s) => s.hasReachedMax, 'max', isFalse),
      ],
    );

    blocTest<DashboardBloc, DashboardState>(
      'LoadTasks soft-fails and keeps cache when network fails',
      build: buildBloc,
      setUp: () {
        when(() => getTasksUseCase(any())).thenAnswer((invocation) async {
          final params = invocation.positionalArguments.first as GetTasksParams;
          if (params.cacheOnly) {
            return Right(
              PaginatedTasksPage(tasks: [cachedTask], page: 1, totalPages: 1),
            );
          }
          return const Left(ServerFailure(message: 'Server down'));
        });
      },
      act: (bloc) => bloc.add(const LoadTasks()),
      // Soft-fail re-emits identical Loaded(isFromCache: true); Bloc skips duplicate.
      expect: () => [
        isA<DashboardLoaded>()
            .having((s) => s.isFromCache, 'fromCache', isTrue)
            .having((s) => s.tasks.single.title, 'title', 'Cached Flutter App'),
      ],
      verify: (bloc) {
        expect(bloc.state, isA<DashboardLoaded>());
        expect((bloc.state as DashboardLoaded).isFromCache, isTrue);
      },
    );

    blocTest<DashboardBloc, DashboardState>(
      'LoadMoreTasks appends next page and shows LoadingMore',
      build: buildBloc,
      seed: () =>
          DashboardLoaded(tasks: [task], currentPage: 1, hasReachedMax: false),
      setUp: () {
        when(() => getTasksUseCase(any())).thenAnswer(
          (_) async => Right(
            PaginatedTasksPage(tasks: [taskPage2], page: 2, totalPages: 2),
          ),
        );
      },
      act: (bloc) => bloc.add(const LoadMoreTasks()),
      expect: () => [
        isA<DashboardLoadingMore>().having((s) => s.tasks.length, 'tasks', 1),
        isA<DashboardLoaded>()
            .having((s) => s.tasks.length, 'tasks', 2)
            .having((s) => s.currentPage, 'page', 2)
            .having((s) => s.hasReachedMax, 'max', isTrue),
      ],
    );

    blocTest<DashboardBloc, DashboardState>(
      'LoadMoreTasks is ignored when hasReachedMax',
      build: buildBloc,
      seed: () =>
          DashboardLoaded(tasks: [task], currentPage: 2, hasReachedMax: true),
      act: (bloc) => bloc.add(const LoadMoreTasks()),
      expect: () => <DashboardState>[],
    );

    blocTest<DashboardBloc, DashboardState>(
      'RefreshTasks reloads page 1',
      build: buildBloc,
      seed: () => DashboardLoaded(
        tasks: [task, taskPage2],
        currentPage: 2,
        hasReachedMax: true,
      ),
      setUp: () {
        when(() => getTasksUseCase(any())).thenAnswer(
          (_) async =>
              Right(PaginatedTasksPage(tasks: [task], page: 1, totalPages: 5)),
        );
      },
      act: (bloc) => bloc.add(const RefreshTasks()),
      expect: () => [
        isA<DashboardLoaded>()
            .having((s) => s.tasks.length, 'tasks', 1)
            .having((s) => s.currentPage, 'page', 1)
            .having((s) => s.hasReachedMax, 'max', isFalse),
      ],
    );

    blocTest<DashboardBloc, DashboardState>(
      'LoadTasks emits DashboardError on failure when cache empty',
      build: buildBloc,
      setUp: () {
        stubEmptyCacheThen(
          (_) async => const Left(ServerFailure(message: 'Server down')),
        );
      },
      act: (bloc) => bloc.add(const LoadTasks()),
      expect: () => [
        const DashboardLoading(),
        const DashboardError(message: 'Server down'),
      ],
    );

    blocTest<DashboardBloc, DashboardState>(
      'SearchTasksChanged and ApplyTaskFilters combine in GetTasksParams',
      build: buildBloc,
      seed: () =>
          DashboardLoaded(tasks: [task], currentPage: 1, hasReachedMax: true),
      setUp: () {
        when(() => getTasksUseCase(any())).thenAnswer(
          (_) async =>
              Right(PaginatedTasksPage(tasks: [task], page: 1, totalPages: 1)),
        );
      },
      act: (bloc) async {
        bloc.add(const SearchTasksChanged('flutter'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const ApplyTaskFilters(
            status: TaskStatus.pending,
            priority: TaskPriority.high,
          ),
        );
      },
      wait: const Duration(milliseconds: 10),
      expect: () => [
        isA<DashboardLoaded>().having(
          (s) => s.searchQuery,
          'search',
          'flutter',
        ),
        isA<DashboardLoaded>()
            .having((s) => s.searchQuery, 'search', 'flutter')
            .having((s) => s.statusFilter, 'status', TaskStatus.pending)
            .having((s) => s.priorityFilter, 'priority', TaskPriority.high),
      ],
      verify: (_) {
        final captured = verify(
          () => getTasksUseCase(captureAny()),
        ).captured.cast<GetTasksParams>();
        expect(
          captured.any(
            (p) =>
                !p.cacheOnly &&
                p.searchQuery == 'flutter' &&
                p.status == TaskStatus.pending &&
                p.priority == TaskPriority.high,
          ),
          isTrue,
        );
      },
    );
  });
}
