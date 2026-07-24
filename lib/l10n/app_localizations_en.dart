// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Team Workspace';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get clear => 'Clear';

  @override
  String get apply => 'Apply';

  @override
  String get all => 'All';

  @override
  String get logout => 'Logout';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get hindi => 'Hindi';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get createAccount => 'Create Account';

  @override
  String get login => 'Login';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'Enter your email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get createAnAccount => 'Create an account';

  @override
  String get alreadyHaveAccountLogin => 'Already have an account? Login';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get emailInvalid => 'Enter a valid email';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String passwordMinLength(int min) {
    return 'Password must be at least $min characters';
  }

  @override
  String get confirmPasswordRequired => 'Please confirm your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String fieldRequired(String field) {
    return '$field is required';
  }

  @override
  String get tasksTitle => 'Tasks';

  @override
  String get filters => 'Filters';

  @override
  String get createTask => 'Create Task';

  @override
  String get editTask => 'Edit Task';

  @override
  String get updateTask => 'Update Task';

  @override
  String get taskDetails => 'Task Details';

  @override
  String get searchTasksHint => 'Search tasks by title';

  @override
  String get searchTasksSemantics => 'Search tasks';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get noTasksYet => 'No tasks yet.';

  @override
  String get noTasksFound => 'No tasks found';

  @override
  String get tryChangingSearchOrFilters =>
      'Try changing your search or filters.';

  @override
  String get status => 'Status';

  @override
  String get priority => 'Priority';

  @override
  String get clearAll => 'Clear all';

  @override
  String get removeStatusFilter => 'Remove status filter';

  @override
  String get removePriorityFilter => 'Remove priority filter';

  @override
  String get dueDate => 'Due Date';

  @override
  String duePrefix(String date) {
    return 'Due $date';
  }

  @override
  String get waitingForSync => 'Waiting for sync';

  @override
  String openTaskSemantics(String title) {
    return 'Open task $title';
  }

  @override
  String get title => 'Title';

  @override
  String get description => 'Description';

  @override
  String get assignedUser => 'Assigned User';

  @override
  String get lastUpdated => 'Last Updated';

  @override
  String get markCompleted => 'Mark Completed';

  @override
  String get reopenTask => 'Reopen Task';

  @override
  String get editTaskTooltip => 'Edit task';

  @override
  String get titleRequired => 'Title is required';

  @override
  String titleTooShort(int min) {
    return 'Title must be at least $min characters';
  }

  @override
  String titleTooLong(int max) {
    return 'Title must be at most $max characters';
  }

  @override
  String get descriptionRequired => 'Description is required';

  @override
  String descriptionTooShort(int min) {
    return 'Description must be at least $min characters';
  }

  @override
  String get priorityRequired => 'Priority is required';

  @override
  String get dueDateRequired => 'Due date is required';

  @override
  String get dueDateInvalid => 'Enter a valid due date';

  @override
  String get dueDateInPast => 'Due date cannot be in the past';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusInProgress => 'In Progress';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String get taskCreatedSuccess => 'Task created successfully';

  @override
  String get taskUpdatedSuccess => 'Task updated successfully';

  @override
  String get taskMarkedCompleted => 'Task marked as completed';

  @override
  String get taskReopened => 'Task reopened';

  @override
  String get savedOfflineWaitingSync => 'Saved offline — waiting for sync';

  @override
  String get taskNotFound => 'Task not found.';

  @override
  String get youAreOffline => 'You are offline';

  @override
  String offlinePendingCount(int count) {
    return 'Offline · $count waiting for sync';
  }

  @override
  String get syncingChanges => 'Syncing changes…';

  @override
  String pendingCountWaiting(int count) {
    return '$count waiting for sync';
  }

  @override
  String get backOnline => 'Back online';

  @override
  String syncedCount(int count) {
    return 'Synced $count change(s)';
  }

  @override
  String syncedPartialFailure(int synced, int failed) {
    return 'Synced $synced, failed $failed.';
  }

  @override
  String get somethingWentWrong => 'Something went wrong. Please try again.';

  @override
  String get selectDate => 'Select date';

  @override
  String get noDescription => 'No description provided.';

  @override
  String get profile => 'Profile';

  @override
  String get theme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get openProfile => 'Open profile';
}
