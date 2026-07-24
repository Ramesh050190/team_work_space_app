import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/features/authentication/data/models/user_model.dart';
import 'package:team_workspace/features/authentication/domain/entities/app_user.dart';

class _MockUser extends Mock implements User {}

void main() {
  group('UserModel', () {
    test('fromFirebaseUser maps fields and null email to empty string', () {
      final user = _MockUser();
      when(() => user.uid).thenReturn('uid-9');
      when(() => user.email).thenReturn(null);
      when(() => user.displayName).thenReturn('Ada');

      final model = UserModel.fromFirebaseUser(user);

      expect(model.uid, 'uid-9');
      expect(model.email, '');
      expect(model.displayName, 'Ada');
    });

    test('toEntity and props equality', () {
      const a = UserModel(uid: 'u1', email: 'a@b.com', displayName: 'A');
      const b = UserModel(uid: 'u1', email: 'a@b.com', displayName: 'A');
      const c = UserModel(uid: 'u2', email: 'a@b.com', displayName: 'A');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(
        a.toEntity(),
        const AppUser(uid: 'u1', email: 'a@b.com', displayName: 'A'),
      );
    });
  });
}
