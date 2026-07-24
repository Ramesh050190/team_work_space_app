import 'package:team_workspace/core/errors/failure.dart';

class TimeoutFailure extends Failure {
  const TimeoutFailure({
    super.message = 'Request timed out. Please try again.',
  });
}
