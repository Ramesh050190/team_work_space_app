import 'package:dartz/dartz.dart';
import 'package:team_workspace/core/errors/failure.dart';
import 'package:team_workspace/features/authentication/domain/entities/app_user.dart';
import 'package:team_workspace/features/authentication/domain/repositories/auth_repository.dart';

class SignupUseCase {
  const SignupUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, AppUser>> call({
    required String email,
    required String password,
  }) {
    return _repository.signup(email: email, password: password);
  }
}
