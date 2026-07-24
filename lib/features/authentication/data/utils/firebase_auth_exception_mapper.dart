import 'package:firebase_auth/firebase_auth.dart';
import 'package:team_workspace/features/authentication/data/exceptions/auth_exception.dart';

class FirebaseAuthExceptionMapper {
  FirebaseAuthExceptionMapper._();

  static AuthException map(FirebaseAuthException exception) {
    final code = exception.code;
    final message = _messageForCode(code);

    return AuthException(code: code, message: message);
  }

  static String _messageForCode(String code) {
    switch (code) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
