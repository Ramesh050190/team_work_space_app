import 'package:flutter_test/flutter_test.dart';
import 'package:team_workspace/core/constants/message_keys.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/validators/task_form_validator.dart';

void main() {
  group('TaskFormValidator', () {
    group('validateTitle', () {
      test('empty / short / long / valid', () {
        expect(
          TaskFormValidator.validateTitle(null),
          MessageKeys.titleRequired,
        );
        expect(
          TaskFormValidator.validateTitle('  '),
          MessageKeys.titleRequired,
        );
        expect(
          TaskFormValidator.validateTitle('ab'),
          MessageKeys.titleTooShort,
        );
        expect(
          TaskFormValidator.validateTitle('a' * 101),
          MessageKeys.titleTooLong,
        );
        expect(TaskFormValidator.validateTitle('Valid title'), isNull);
      });
    });

    group('validateDescription', () {
      test('empty / short / valid', () {
        expect(
          TaskFormValidator.validateDescription(''),
          MessageKeys.descriptionRequired,
        );
        expect(
          TaskFormValidator.validateDescription('short'),
          MessageKeys.descriptionTooShort,
        );
        expect(
          TaskFormValidator.validateDescription('Long enough description'),
          isNull,
        );
      });
    });

    group('validatePriority', () {
      test('null vs set', () {
        expect(
          TaskFormValidator.validatePriority(null),
          MessageKeys.priorityRequired,
        );
        expect(TaskFormValidator.validatePriority(TaskPriority.high), isNull);
      });
    });

    group('validateDueDate', () {
      test('null / past / today / future', () {
        expect(
          TaskFormValidator.validateDueDate(null),
          MessageKeys.dueDateRequired,
        );

        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(
          TaskFormValidator.validateDueDate(yesterday),
          MessageKeys.dueDateInPast,
        );

        final today = DateTime.now();
        expect(TaskFormValidator.validateDueDate(today), isNull);

        final tomorrow = DateTime.now().add(const Duration(days: 1));
        expect(TaskFormValidator.validateDueDate(tomorrow), isNull);
      });
    });
  });
}
