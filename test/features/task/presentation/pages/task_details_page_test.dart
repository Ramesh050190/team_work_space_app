import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_workspace/features/task/presentation/widgets/task_info_card.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/pump_with_l10n.dart';

void main() {
  group('TaskInfoCard', () {
    testWidgets('displays description and assignee', (tester) async {
      final task = FakeData.task(
        title: 'Detail Task',
        description: 'Full description here',
      );

      await tester.pumpWidget(
        pumpWithL10n(
          Scaffold(
            body: SingleChildScrollView(child: TaskInfoCard(task: task)),
          ),
        ),
      );

      expect(find.text('Full description here'), findsOneWidget);
      expect(find.text('Alex Morgan'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Assigned User'), findsOneWidget);
    });
  });
}
