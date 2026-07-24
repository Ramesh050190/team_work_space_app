import 'package:flutter_test/flutter_test.dart';
import 'package:team_workspace/features/authentication/domain/entities/app_user.dart';
import 'package:team_workspace/features/authentication/presentation/bloc/auth_event.dart';
import 'package:team_workspace/features/authentication/presentation/bloc/auth_state.dart';

void main() {
  const user = AppUser(uid: 'u1', email: 'a@b.com', displayName: 'A');

  group('AuthEvent props', () {
    test('login / signup / state changed', () {
      expect(
        const AuthLoginRequested(email: 'a', password: 'b'),
        const AuthLoginRequested(email: 'a', password: 'b'),
      );
      expect(
        const AuthSignupRequested(email: 'a', password: 'b'),
        isNot(const AuthSignupRequested(email: 'a', password: 'c')),
      );
      expect(const AuthStateChanged(user), const AuthStateChanged(user));
      expect(const AuthStateChanged(null), isNot(const AuthStateChanged(user)));
    });
  });

  group('AuthState props', () {
    test('authenticated and failure', () {
      expect(const AuthAuthenticated(user), const AuthAuthenticated(user));
      expect(const AuthFailure('x'), const AuthFailure('x'));
      expect(const AuthFailure('x'), isNot(const AuthFailure('y')));
    });
  });
}
