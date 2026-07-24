import 'failure.dart';

/// Raised when local and remote task versions diverge.
class ConflictFailure extends Failure {
  const ConflictFailure({
    required super.message,
    this.localUpdatedAt,
    this.remoteUpdatedAt,
  });

  final DateTime? localUpdatedAt;
  final DateTime? remoteUpdatedAt;

  @override
  List<Object?> get props => [message, localUpdatedAt, remoteUpdatedAt];
}
