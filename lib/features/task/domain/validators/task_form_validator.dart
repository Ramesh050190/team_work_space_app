import 'package:team_workspace/core/constants/message_keys.dart';

/// Domain validation helpers for create/edit task forms.
/// Returns [MessageKeys] so UI can localize via [AppStrings.resolveMessage].
class TaskFormValidator {
  TaskFormValidator._();

  static String? validateTitle(String? value) {
    final title = value?.trim() ?? '';
    if (title.isEmpty) {
      return MessageKeys.titleRequired;
    }
    if (title.length < 3) {
      return MessageKeys.titleTooShort;
    }
    if (title.length > 100) {
      return MessageKeys.titleTooLong;
    }
    return null;
  }

  static String? validateDescription(String? value) {
    final description = value?.trim() ?? '';
    if (description.isEmpty) {
      return MessageKeys.descriptionRequired;
    }
    if (description.length < 10) {
      return MessageKeys.descriptionTooShort;
    }
    return null;
  }

  static String? validatePriority(Object? value) {
    if (value == null) {
      return MessageKeys.priorityRequired;
    }
    return null;
  }

  static String? validateDueDate(DateTime? value) {
    if (value == null) {
      return MessageKeys.dueDateRequired;
    }

    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final dueDay = DateTime(value.year, value.month, value.day);

    if (dueDay.isBefore(startOfToday)) {
      return MessageKeys.dueDateInPast;
    }
    return null;
  }
}
