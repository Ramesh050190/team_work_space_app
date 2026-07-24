import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart' hide Task;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/core/errors/server_failure.dart';
import 'package:team_workspace/features/task/domain/entities/assigned_user.dart';
import 'package:team_workspace/features/task/domain/entities/task.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';
import 'package:team_workspace/features/task/domain/usecases/create_task_usecase.dart';
import 'package:team_workspace/features/task/domain/usecases/update_task_usecase.dart';
import 'package:team_workspace/features/task/presentation/bloc/task_form/task_form_bloc.dart';
import 'package:team_workspace/features/task/presentation/bloc/task_form/task_form_event.dart';
import 'package:team_workspace/features/task/presentation/bloc/task_form/task_form_state.dart';

class _MockCreateTaskUseCase extends Mock implements CreateTaskUseCase {}

class _MockUpdateTaskUseCase extends Mock implements UpdateTaskUseCase {}

void main() {
  late _MockCreateTaskUseCase createTaskUseCase;
  late _MockUpdateTaskUseCase updateTaskUseCase;

  final futureDue = DateTime.now().add(const Duration(days: 3));

  final existingTask = Task(
    id: 1,
    title: 'Existing task',
    description: 'Existing description long enough',
    priority: TaskPriority.medium,
    status: TaskStatus.pending,
    dueDate: futureDue,
    assignedUser: const AssignedUser(
      id: 'u1',
      name: 'Alex',
      email: 'alex@example.com',
    ),
    createdAt: DateTime.parse('2026-07-20T08:00:00.000Z'),
    updatedAt: DateTime.parse('2026-07-20T08:00:00.000Z'),
    completed: false,
  );

  setUpAll(() {
    registerFallbackValue(CreateTaskParams(task: existingTask));
    registerFallbackValue(UpdateTaskParams(task: existingTask));
  });

  setUp(() {
    createTaskUseCase = _MockCreateTaskUseCase();
    updateTaskUseCase = _MockUpdateTaskUseCase();
  });

  TaskFormBloc buildBloc() {
    return TaskFormBloc(
      createTaskUseCase: createTaskUseCase,
      updateTaskUseCase: updateTaskUseCase,
    );
  }

  group('TaskFormBloc', () {
    blocTest<TaskFormBloc, TaskFormState>(
      'InitializeForm create emits Editing with defaults',
      build: buildBloc,
      act: (bloc) => bloc.add(const InitializeForm(mode: TaskFormMode.create)),
      expect: () => [
        isA<TaskFormEditing>()
            .having((s) => s.mode, 'mode', TaskFormMode.create)
            .having((s) => s.priority, 'priority', TaskPriority.medium),
      ],
    );

    blocTest<TaskFormBloc, TaskFormState>(
      'InitializeForm edit prefills existing task',
      build: buildBloc,
      act: (bloc) => bloc.add(
        InitializeForm(mode: TaskFormMode.edit, existingTask: existingTask),
      ),
      expect: () => [
        isA<TaskFormEditing>()
            .having((s) => s.mode, 'mode', TaskFormMode.edit)
            .having((s) => s.title, 'title', 'Existing task')
            .having((s) => s.taskId, 'taskId', 1),
      ],
    );

    blocTest<TaskFormBloc, TaskFormState>(
      'SubmitCreateTask emits ValidationError when title is invalid',
      build: buildBloc,
      seed: () => TaskFormEditing(
        mode: TaskFormMode.create,
        title: 'ab',
        description: 'Valid description here',
        priority: TaskPriority.high,
        status: TaskStatus.pending,
        dueDate: futureDue,
      ),
      act: (bloc) => bloc.add(const SubmitCreateTask()),
      expect: () => [
        isA<TaskFormValidationError>(),
        isA<TaskFormEditing>().having(
          (s) => s.titleError,
          'titleError',
          isNotNull,
        ),
      ],
    );

    blocTest<TaskFormBloc, TaskFormState>(
      'TitleChanged clears titleError once title becomes valid',
      build: buildBloc,
      seed: () => TaskFormEditing(
        mode: TaskFormMode.create,
        title: '',
        description: 'Valid description here',
        priority: TaskPriority.high,
        status: TaskStatus.pending,
        dueDate: futureDue,
        titleError: 'title_required',
        descriptionError: 'description_required',
      ),
      act: (bloc) {
        bloc
          ..add(const TitleChanged('Valid title'))
          ..add(const DescriptionChanged('Valid description here'));
      },
      expect: () => [
        isA<TaskFormEditing>()
            .having((s) => s.title, 'title', 'Valid title')
            .having((s) => s.titleError, 'titleError', isNull)
            .having(
              (s) => s.descriptionError,
              'descriptionError',
              'description_required',
            ),
        isA<TaskFormEditing>()
            .having((s) => s.descriptionError, 'descriptionError', isNull)
            .having((s) => s.titleError, 'titleError', isNull),
      ],
    );

    blocTest<TaskFormBloc, TaskFormState>(
      'SubmitCreateTask emits Success when valid',
      build: buildBloc,
      seed: () => TaskFormEditing(
        mode: TaskFormMode.create,
        title: 'New task title',
        description: 'Valid description here',
        priority: TaskPriority.high,
        status: TaskStatus.pending,
        dueDate: futureDue,
      ),
      setUp: () {
        when(() => createTaskUseCase(any())).thenAnswer(
          (_) async => Right(
            existingTask.copyWith(
              id: 10,
              title: 'New task title',
              description: 'Valid description here',
              priority: TaskPriority.high,
            ),
          ),
        );
      },
      act: (bloc) => bloc.add(const SubmitCreateTask()),
      expect: () => [
        isA<TaskFormSubmitting>(),
        isA<TaskFormSuccess>().having(
          (s) => s.message,
          'message',
          'task_created_success',
        ),
      ],
    );

    blocTest<TaskFormBloc, TaskFormState>(
      'SubmitUpdateTask emits Failure then Editing on API error',
      build: buildBloc,
      seed: () => TaskFormEditing(
        mode: TaskFormMode.edit,
        taskId: 1,
        existingTask: existingTask,
        title: 'Updated title',
        description: 'Valid description here',
        priority: TaskPriority.low,
        status: TaskStatus.inProgress,
        dueDate: futureDue,
      ),
      setUp: () {
        when(() => updateTaskUseCase(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Update failed')),
        );
      },
      act: (bloc) => bloc.add(const SubmitUpdateTask()),
      expect: () => [
        isA<TaskFormSubmitting>(),
        isA<TaskFormFailure>().having(
          (s) => s.message,
          'message',
          'Update failed',
        ),
        isA<TaskFormEditing>().having(
          (s) => s.submitError,
          'submitError',
          'Update failed',
        ),
      ],
    );

    blocTest<TaskFormBloc, TaskFormState>(
      'SubmitUpdateTask emits Success when valid',
      build: buildBloc,
      seed: () => TaskFormEditing(
        mode: TaskFormMode.edit,
        taskId: 1,
        existingTask: existingTask,
        title: 'Updated title',
        description: 'Valid description here',
        priority: TaskPriority.low,
        status: TaskStatus.completed,
        dueDate: futureDue,
      ),
      setUp: () {
        when(() => updateTaskUseCase(any())).thenAnswer(
          (_) async => Right(
            existingTask.copyWith(
              title: 'Updated title',
              status: TaskStatus.completed,
              completed: true,
              priority: TaskPriority.low,
            ),
          ),
        );
      },
      act: (bloc) => bloc.add(const SubmitUpdateTask()),
      expect: () => [
        isA<TaskFormSubmitting>(),
        isA<TaskFormSuccess>().having((s) => s.mode, 'mode', TaskFormMode.edit),
      ],
    );
  });
}
