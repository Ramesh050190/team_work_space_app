import 'package:dartz/dartz.dart';
import 'package:team_workspace/core/errors/failure.dart';
import 'package:team_workspace/features/authentication/domain/entities/app_user.dart';
import 'package:team_workspace/features/authentication/domain/repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  const GetCurrentUserUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, AppUser?>> call() {
    return _repository.currentUser();
  }

  Stream<AppUser?> watchAuthState() {
    return _repository.authStateChanges();
  }
}
