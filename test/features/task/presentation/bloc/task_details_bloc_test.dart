import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart' hide Task;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/core/errors/server_failure.dart';
import 'package:team_workspace/features/task/data/datasources/task_local_datasource.dart';
import 'package:team_workspace/features/task/domain/entities/assigned_user.dart';
import 'package:team_workspace/features/task/domain/entities/task.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';
import 'package:team_workspace/features/task/domain/usecases/get_task_details_usecase.dart';
import 'package:team_workspace/features/task/domain/usecases/update_task_status_usecase.dart';
import 'package:team_workspace/features/task/presentation/bloc/task_details_bloc.dart';
import 'package:team_workspace/features/task/presentation/bloc/task_details_event.dart';
import 'package:team_workspace/features/task/presentation/bloc/task_details_state.dart';

class _MockGetTaskDetailsUseCase extends Mock
    implements GetTaskDetailsUseCase {}

class _MockUpdateTaskStatusUseCase extends Mock
    implements UpdateTaskStatusUseCase {}

class _MockTaskLocalDataSource extends Mock implements TaskLocalDataSource {}

void main() {
  late _MockGetTaskDetailsUseCase getTaskDetailsUseCase;
  late _MockUpdateTaskStatusUseCase updateTaskStatusUseCase;
  late _MockTaskLocalDataSource taskLocalDataSource;

  final task = Task(
    id: 1,
    title: 'Sample',
    description: 'Description',
    priority: TaskPriority.medium,
    status: TaskStatus.pending,
    dueDate: DateTime.parse('2026-07-25T00:00:00.000Z'),
    assignedUser: const AssignedUser(
      id: 'u1',
      name: 'Alex',
      email: 'alex@example.com',
    ),
    createdAt: DateTime.parse('2026-07-20T08:00:00.000Z'),
    updatedAt: DateTime.parse('2026-07-20T08:00:00.000Z'),
    completed: false,
  );

  final completedTask = task.copyWith(
    completed: true,
    status: TaskStatus.completed,
  );

  setUpAll(() {
    registerFallbackValue(const GetTaskDetailsParams(id: 1));
    registerFallbackValue(const UpdateTaskStatusParams(id: 1, completed: true));
  });

  setUp(() {
    getTaskDetailsUseCase = _MockGetTaskDetailsUseCase();
    updateTaskStatusUseCase = _MockUpdateTaskStatusUseCase();
    taskLocalDataSource = _MockTaskLocalDataSource();
    when(
      () => taskLocalDataSource.getCachedTaskDetails(any()),
    ).thenAnswer((_) async => null);
    when(
      () => taskLocalDataSource.hasPendingOperationsForTask(any()),
    ).thenAnswer((_) async => false);
  });

  TaskDetailsBloc buildBloc() {
    return TaskDetailsBloc(
      getTaskDetailsUseCase: getTaskDetailsUseCase,
      updateTaskStatusUseCase: updateTaskStatusUseCase,
      taskId: 1,
      taskLocalDataSource: taskLocalDataSource,
    );
  }

  group('TaskDetailsBloc', () {
    blocTest<TaskDetailsBloc, TaskDetailsState>(
      'emits [Loading, Loaded] when LoadTaskDetails succeeds',
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadTaskDetails(1)),
      setUp: () {
        when(
          () => getTaskDetailsUseCase(any()),
        ).thenAnswer((_) async => Right(task));
      },
      expect: () => [const TaskDetailsLoading(), TaskDetailsLoaded(task: task)],
    );

    blocTest<TaskDetailsBloc, TaskDetailsState>(
      'emits [Loading, Failure] when LoadTaskDetails fails',
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadTaskDetails(1)),
      setUp: () {
        when(() => getTaskDetailsUseCase(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Server down')),
        );
      },
      expect: () => const [
        TaskDetailsLoading(),
        TaskDetailsFailure(message: 'Server down'),
      ],
    );

    blocTest<TaskDetailsBloc, TaskDetailsState>(
      'optimistically updates then emits Success and Loaded on MarkCompleted',
      build: buildBloc,
      seed: () => TaskDetailsLoaded(task: task),
      act: (bloc) => bloc.add(const MarkCompleted()),
      setUp: () {
        when(
          () => updateTaskStatusUseCase(any()),
        ).thenAnswer((_) async => Right(completedTask));
      },
      expect: () => [
        isA<TaskDetailsUpdating>().having(
          (state) => state.task.completed,
          'optimistic completed',
          isTrue,
        ),
        TaskDetailsSuccess(
          task: completedTask,
          message: 'task_marked_completed',
        ),
        TaskDetailsLoaded(task: completedTask),
      ],
    );

    blocTest<TaskDetailsBloc, TaskDetailsState>(
      'rolls back task when MarkCompleted fails',
      build: buildBloc,
      seed: () => TaskDetailsLoaded(task: task),
      act: (bloc) => bloc.add(const MarkCompleted()),
      setUp: () {
        when(() => updateTaskStatusUseCase(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Update failed')),
        );
      },
      expect: () => [
        isA<TaskDetailsUpdating>(),
        TaskDetailsLoaded(task: task, statusUpdateMessage: 'Update failed'),
      ],
    );

    blocTest<TaskDetailsBloc, TaskDetailsState>(
      'ReopenTask emits Success with reopened task',
      build: buildBloc,
      seed: () => TaskDetailsLoaded(task: completedTask),
      act: (bloc) => bloc.add(const ReopenTask()),
      setUp: () {
        when(
          () => updateTaskStatusUseCase(any()),
        ).thenAnswer((_) async => Right(task));
      },
      expect: () => [
        isA<TaskDetailsUpdating>().having(
          (state) => state.task.completed,
          'optimistic reopened',
          isFalse,
        ),
        TaskDetailsSuccess(task: task, message: 'task_reopened'),
        TaskDetailsLoaded(task: task),
      ],
    );
  });
}
