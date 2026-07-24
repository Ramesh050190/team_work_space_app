import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';
import 'package:team_workspace/features/task/domain/usecases/create_task_usecase.dart';
import 'package:team_workspace/features/task/domain/usecases/update_task_usecase.dart';
import 'package:team_workspace/features/task/presentation/bloc/task_form/task_form_bloc.dart';
import 'package:team_workspace/features/task/presentation/bloc/task_form/task_form_event.dart';
import 'package:team_workspace/features/task/presentation/bloc/task_form/task_form_state.dart';
import 'package:team_workspace/features/task/presentation/widgets/task_form.dart';

import '../../../../helpers/pump_with_l10n.dart';

class _MockCreateTaskUseCase extends Mock implements CreateTaskUseCase {}

class _MockUpdateTaskUseCase extends Mock implements UpdateTaskUseCase {}

void main() {
  late TaskFormBloc bloc;

  setUp(() {
    bloc = TaskFormBloc(
      createTaskUseCase: _MockCreateTaskUseCase(),
      updateTaskUseCase: _MockUpdateTaskUseCase(),
    );
  });

  tearDown(() async {
    await bloc.close();
  });

  testWidgets('TaskForm shows create fields and button', (tester) async {
    bloc.add(const InitializeForm(mode: TaskFormMode.create));
    await tester.pump();

    await tester.pumpWidget(
      pumpWithL10n(
        Scaffold(
          body: BlocProvider.value(value: bloc, child: const TaskForm()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Priority'), findsOneWidget);
    expect(find.text('Due Date'), findsOneWidget);
    expect(find.text('Create Task'), findsOneWidget);
    expect(find.text('Status'), findsNothing);
  });

  testWidgets('TaskForm shows status dropdown in edit mode', (tester) async {
    final due = DateTime.now().add(const Duration(days: 2));
    bloc.emit(
      TaskFormEditing(
        mode: TaskFormMode.edit,
        taskId: 1,
        title: 'Edit me',
        description: 'Description long enough',
        priority: TaskPriority.medium,
        status: TaskStatus.pending,
        dueDate: due,
      ),
    );

    await tester.pumpWidget(
      pumpWithL10n(
        Scaffold(
          body: BlocProvider.value(value: bloc, child: const TaskForm()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Update Task'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
  });
}
