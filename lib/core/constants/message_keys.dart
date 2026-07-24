class MessageKeys {
  MessageKeys._();

  static const waitingForSync = 'waiting_for_sync';
  static const savedOfflineWaitingSync = 'saved_offline_waiting_sync';
  static const taskCreatedSuccess = 'task_created_success';
  static const taskUpdatedSuccess = 'task_updated_success';
  static const taskMarkedCompleted = 'task_marked_completed';
  static const taskReopened = 'task_reopened';
  static const taskNotFound = 'task_not_found';
  static const backOnline = 'back_online';
  static const youAreOffline = 'you_are_offline';
  static const syncingChanges = 'syncing_changes';

  /// Form validation
  static const titleRequired = 'title_required';
  static const titleTooShort = 'title_too_short';
  static const titleTooLong = 'title_too_long';
  static const descriptionRequired = 'description_required';
  static const descriptionTooShort = 'description_too_short';
  static const priorityRequired = 'priority_required';
  static const dueDateRequired = 'due_date_required';
  static const dueDateInPast = 'due_date_in_past';

  /// Encoded sync success: synced_count:<n>
  static String syncedCount(int count) => 'synced_count:$count';

  /// Encoded partial sync: synced_partial:<synced>:<failed>
  static String syncedPartial({required int synced, required int failed}) =>
      'synced_partial:$synced:$failed';
}
