import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_workspace/features/dashboard/presentation/widgets/task_filter_bottom_sheet.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';

import '../../../../helpers/pump_with_l10n.dart';

void main() {
  testWidgets('applies selected status and priority', (tester) async {
    TaskStatus? appliedStatus;
    TaskPriority? appliedPriority;

    await tester.pumpWidget(
      pumpWithL10n(
        Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  TaskFilterBottomSheet.show(
                    context,
                    initialStatus: TaskStatus.pending,
                    initialPriority: TaskPriority.low,
                    onApply: ({status, priority}) {
                      appliedStatus = status;
                      appliedPriority = priority;
                    },
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Filters'), findsOneWidget);

    await tester.tap(find.text('Completed'));
    await tester.pump();
    await tester.tap(find.text('High'));
    await tester.pump();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(appliedStatus, TaskStatus.completed);
    expect(appliedPriority, TaskPriority.high);
  });

  testWidgets('clear all resets selections before apply', (tester) async {
    TaskStatus? appliedStatus = TaskStatus.pending;
    TaskPriority? appliedPriority = TaskPriority.high;

    await tester.pumpWidget(
      pumpWithL10n(
        Scaffold(
          body: TaskFilterBottomSheet(
            initialStatus: TaskStatus.pending,
            initialPriority: TaskPriority.high,
            onApply: ({status, priority}) {
              appliedStatus = status;
              appliedPriority = priority;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Clear all'));
    await tester.pump();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(appliedStatus, isNull);
    expect(appliedPriority, isNull);
  });
}
