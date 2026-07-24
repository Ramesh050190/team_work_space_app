import 'package:flutter_test/flutter_test.dart';
import 'package:team_workspace/core/constants/app_strings.dart';
import 'package:team_workspace/core/constants/message_keys.dart';
import 'package:team_workspace/l10n/app_localizations_en.dart';

void main() {
  late AppStrings strings;

  setUp(() {
    strings = AppStrings(AppLocalizationsEn());
  });

  group('AppStrings.resolveMessage', () {
    test('maps known MessageKeys to localized copy', () {
      expect(
        strings.resolveMessage(MessageKeys.taskCreatedSuccess),
        'Task created successfully',
      );
      expect(strings.resolveMessage(MessageKeys.backOnline), 'Back online');
    });

    test('maps synced count encodings', () {
      expect(strings.resolveMessage('synced_count:3'), 'Synced 3 change(s)');
      expect(
        strings.resolveMessage('synced_partial:2:1'),
        'Synced 2, failed 1.',
      );
    });

    test('passes through unknown messages', () {
      expect(strings.resolveMessage('Raw server error'), 'Raw server error');
      expect(strings.resolveMessage(null), '');
    });
  });
}
