import 'package:team_workspace/features/authentication/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String email, required String password});

  Future<UserModel> signup({required String email, required String password});

  Future<void> logout();

  Future<UserModel?> getCurrentUser();

  Stream<UserModel?> authStateChanges();
}
