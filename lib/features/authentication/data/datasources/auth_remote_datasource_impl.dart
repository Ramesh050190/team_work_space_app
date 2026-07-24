import 'package:firebase_auth/firebase_auth.dart';
import 'package:team_workspace/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:team_workspace/features/authentication/data/exceptions/auth_exception.dart';
import 'package:team_workspace/features/authentication/data/models/user_model.dart';
import 'package:team_workspace/features/authentication/data/utils/firebase_auth_exception_mapper.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({required FirebaseAuth firebaseAuth})
    : _firebaseAuth = firebaseAuth;

  final FirebaseAuth _firebaseAuth;

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthException(
          code: 'user-not-found',
          message: 'Unable to sign in. Please try again.',
        );
      }

      return UserModel.fromFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthExceptionMapper.map(e);
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException(
        code: 'unknown',
        message: 'An unexpected error occurred during sign in.',
      );
    }
  }

  @override
  Future<UserModel> signup({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthException(
          code: 'unknown',
          message: 'Unable to create account. Please try again.',
        );
      }

      return UserModel.fromFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthExceptionMapper.map(e);
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException(
        code: 'unknown',
        message: 'An unexpected error occurred during sign up.',
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthExceptionMapper.map(e);
    } catch (_) {
      throw const AuthException(
        code: 'unknown',
        message: 'An unexpected error occurred during sign out.',
      );
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return UserModel.fromFirebaseUser(user);
  }

  @override
  Stream<UserModel?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map((user) {
      if (user == null) return null;
      return UserModel.fromFirebaseUser(user);
    });
  }
}
