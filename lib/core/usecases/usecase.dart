import 'package:dartz/dartz.dart';
import 'package:team_workspace/core/errors/failure.dart';

/// Contract for single-responsibility use cases.
abstract class UseCase<ReturnType, Params> {
  Future<Either<Failure, ReturnType>> call(Params params);
}

class NoParams {
  const NoParams();
}
