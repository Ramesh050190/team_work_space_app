import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_workspace/features/task/presentation/widgets/validation_message.dart';

import '../../../../helpers/pump_with_l10n.dart';

void main() {
  testWidgets('displays the validation message text', (tester) async {
    await tester.pumpWidget(
      pumpWithL10n(
        const Scaffold(body: ValidationMessage(message: 'Title is required')),
      ),
    );

    expect(find.text('Title is required'), findsOneWidget);
    expect(find.byType(ValidationMessage), findsOneWidget);
  });
}
