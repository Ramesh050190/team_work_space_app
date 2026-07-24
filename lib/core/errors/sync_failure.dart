import 'failure.dart';

class SyncFailure extends Failure {
  const SyncFailure({super.message = 'Failed to sync offline changes.'});
}
