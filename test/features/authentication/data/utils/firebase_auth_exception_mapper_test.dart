import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_workspace/features/authentication/data/exceptions/auth_exception.dart';
import 'package:team_workspace/features/authentication/data/utils/firebase_auth_exception_mapper.dart';

void main() {
  group('FirebaseAuthExceptionMapper', () {
    final cases = <String, String>{
      'invalid-email': 'The email address is not valid.',
      'user-disabled': 'This account has been disabled.',
      'user-not-found': 'No account found with this email.',
      'wrong-password': 'Incorrect password. Please try again.',
      'email-already-in-use': 'An account already exists with this email.',
      'weak-password': 'Password is too weak. Use at least 6 characters.',
      'operation-not-allowed': 'Email/password sign-in is not enabled.',
      'invalid-credential':
          'Invalid credentials. Please check your email and password.',
      'network-request-failed': 'Network error. Please check your connection.',
      'too-many-requests': 'Too many attempts. Please try again later.',
      'some-unknown-code': 'Authentication failed. Please try again.',
    };

    for (final entry in cases.entries) {
      test('maps ${entry.key}', () {
        final mapped = FirebaseAuthExceptionMapper.map(
          FirebaseAuthException(code: entry.key),
        );

        expect(mapped, isA<AuthException>());
        expect(mapped.code, entry.key);
        expect(mapped.message, entry.value);
      });
    }
  });
}
