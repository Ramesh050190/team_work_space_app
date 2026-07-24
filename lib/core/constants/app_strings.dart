import 'package:flutter/widgets.dart';
import 'package:team_workspace/core/constants/app_constants.dart';
import 'package:team_workspace/core/constants/message_keys.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';
import 'package:team_workspace/l10n/app_localizations.dart';
/// Write AppStrings.of(context) in widgets instead of hardcoding copy.
class AppStrings {
  const AppStrings(this._l10n);

  final AppLocalizations _l10n;

  static AppStrings of(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppStrings(l10n);
  }

  AppLocalizations get l10n => _l10n;

  /// Common ---
  String get appName => _l10n.appName;
  String get retry => _l10n.retry;
  String get apply => _l10n.apply;
  String get all => _l10n.all;
  String get logout => _l10n.logout;
  String get language => _l10n.language;
  String get english => _l10n.english;
  String get hindi => _l10n.hindi;
  String get profile => _l10n.profile;
  String get theme => _l10n.theme;
  String get themeLight => _l10n.themeLight;
  String get themeDark => _l10n.themeDark;
  String get themeSystem => _l10n.themeSystem;
  String get openProfile => _l10n.openProfile;

  /// Auth ---
  String get welcomeBack => _l10n.welcomeBack;
  String get createAccount => _l10n.createAccount;
  String get login => _l10n.login;
  String get email => _l10n.email;
  String get emailHint => _l10n.emailHint;
  String get password => _l10n.password;
  String get confirmPassword => _l10n.confirmPassword;
  String get createAnAccount => _l10n.createAnAccount;
  String get alreadyHaveAccountLogin => _l10n.alreadyHaveAccountLogin;
  String get emailRequired => _l10n.emailRequired;
  String get emailInvalid => _l10n.emailInvalid;
  String get passwordRequired => _l10n.passwordRequired;
  String passwordMinLength([int min = AppConstants.minPasswordLength]) =>
      _l10n.passwordMinLength(min);
  String get confirmPasswordRequired => _l10n.confirmPasswordRequired;
  String get passwordsDoNotMatch => _l10n.passwordsDoNotMatch;

  /// Dashboard ---
  String get tasksTitle => _l10n.tasksTitle;
  String get filters => _l10n.filters;
  String get createTask => _l10n.createTask;
  String get editTask => _l10n.editTask;
  String get updateTask => _l10n.updateTask;
  String get taskDetails => _l10n.taskDetails;
  String get searchTasksHint => _l10n.searchTasksHint;
  String get searchTasksSemantics => _l10n.searchTasksSemantics;
  String get clearSearch => _l10n.clearSearch;
  String get noTasksYet => _l10n.noTasksYet;
  String get tryChangingSearchOrFilters => _l10n.tryChangingSearchOrFilters;
  String get status => _l10n.status;
  String get priority => _l10n.priority;
  String get clearAll => _l10n.clearAll;
  String get dueDate => _l10n.dueDate;
  String get waitingForSync => _l10n.waitingForSync;
  String get selectDate => _l10n.selectDate;
  String get noDescription => _l10n.noDescription;

  /// Task ---
  String get title => _l10n.title;
  String get description => _l10n.description;
  String get assignedUser => _l10n.assignedUser;
  String get lastUpdated => _l10n.lastUpdated;
  String get markCompleted => _l10n.markCompleted;
  String get reopenTask => _l10n.reopenTask;
  String get editTaskTooltip => _l10n.editTaskTooltip;
  String get titleRequired => _l10n.titleRequired;
  String titleTooShort(int min) => _l10n.titleTooShort(min);
  String titleTooLong(int max) => _l10n.titleTooLong(max);
  String get descriptionRequired => _l10n.descriptionRequired;
  String descriptionTooShort(int min) => _l10n.descriptionTooShort(min);
  String get priorityRequired => _l10n.priorityRequired;
  String get dueDateRequired => _l10n.dueDateRequired;
  String get dueDateInPast => _l10n.dueDateInPast;
  String get statusPending => _l10n.statusPending;
  String get statusInProgress => _l10n.statusInProgress;
  String get statusCompleted => _l10n.statusCompleted;
  String get priorityLow => _l10n.priorityLow;
  String get priorityMedium => _l10n.priorityMedium;
  String get priorityHigh => _l10n.priorityHigh;
  String get taskCreatedSuccess => _l10n.taskCreatedSuccess;
  String get taskUpdatedSuccess => _l10n.taskUpdatedSuccess;
  String get taskMarkedCompleted => _l10n.taskMarkedCompleted;
  String get taskReopened => _l10n.taskReopened;
  String get savedOfflineWaitingSync => _l10n.savedOfflineWaitingSync;
  String get taskNotFound => _l10n.taskNotFound;

  /// Sync
  String get youAreOffline => _l10n.youAreOffline;
  String offlinePendingCount(int count) => _l10n.offlinePendingCount(count);
  String get syncingChanges => _l10n.syncingChanges;
  String pendingCountWaiting(int count) => _l10n.pendingCountWaiting(count);
  String get backOnline => _l10n.backOnline;
  String syncedCount(int count) => _l10n.syncedCount(count);
  String syncedPartialFailure({required int synced, required int failed}) =>
      _l10n.syncedPartialFailure(synced, failed);

  String statusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return statusPending;
      case TaskStatus.inProgress:
        return statusInProgress;
      case TaskStatus.completed:
        return statusCompleted;
    }
  }

  String priorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return priorityLow;
      case TaskPriority.medium:
        return priorityMedium;
      case TaskPriority.high:
        return priorityHigh;
    }
  }

  String resolveMessage(String? keyOrMessage) {
    if (keyOrMessage == null || keyOrMessage.isEmpty) return '';

    if (keyOrMessage.startsWith('synced_count:')) {
      final count = int.tryParse(keyOrMessage.split(':').elementAt(1)) ?? 0;
      return syncedCount(count);
    }
    if (keyOrMessage.startsWith('synced_partial:')) {
      final parts = keyOrMessage.split(':');
      final synced = int.tryParse(parts.elementAt(1)) ?? 0;
      final failed = int.tryParse(parts.elementAt(2)) ?? 0;
      return syncedPartialFailure(synced: synced, failed: failed);
    }

    switch (keyOrMessage) {
      case MessageKeys.waitingForSync:
        return waitingForSync;
      case MessageKeys.savedOfflineWaitingSync:
        return savedOfflineWaitingSync;
      case MessageKeys.taskCreatedSuccess:
        return taskCreatedSuccess;
      case MessageKeys.taskUpdatedSuccess:
        return taskUpdatedSuccess;
      case MessageKeys.taskMarkedCompleted:
        return taskMarkedCompleted;
      case MessageKeys.taskReopened:
        return taskReopened;
      case MessageKeys.taskNotFound:
        return taskNotFound;
      case MessageKeys.backOnline:
        return backOnline;
      case MessageKeys.youAreOffline:
        return youAreOffline;
      case MessageKeys.syncingChanges:
        return syncingChanges;
      case MessageKeys.titleRequired:
        return titleRequired;
      case MessageKeys.titleTooShort:
        return titleTooShort(3);
      case MessageKeys.titleTooLong:
        return titleTooLong(100);
      case MessageKeys.descriptionRequired:
        return descriptionRequired;
      case MessageKeys.descriptionTooShort:
        return descriptionTooShort(10);
      case MessageKeys.priorityRequired:
        return priorityRequired;
      case MessageKeys.dueDateRequired:
        return dueDateRequired;
      case MessageKeys.dueDateInPast:
        return dueDateInPast;
      default:
        return keyOrMessage;
    }
  }

  /// Validators
  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return emailRequired;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) return emailInvalid;
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return passwordRequired;
    if (value.length < AppConstants.minPasswordLength) {
      return passwordMinLength();
    }
    return null;
  }

  String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return confirmPasswordRequired;
    if (value != password) return passwordsDoNotMatch;
    return null;
  }
}
