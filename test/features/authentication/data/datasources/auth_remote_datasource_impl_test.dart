import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/features/authentication/data/datasources/auth_remote_datasource_impl.dart';
import 'package:team_workspace/features/authentication/data/exceptions/auth_exception.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

void main() {
  late MockFirebaseAuth firebaseAuth;
  late AuthRemoteDataSourceImpl dataSource;
  late MockUser sampleUser;
  late MockUserCredential credentialWithUser;
  late MockUserCredential credentialWithoutUser;

  setUp(() {
    firebaseAuth = MockFirebaseAuth();
    dataSource = AuthRemoteDataSourceImpl(firebaseAuth: firebaseAuth);

    sampleUser = MockUser();
    when(() => sampleUser.uid).thenReturn('uid-1');
    when(() => sampleUser.email).thenReturn('test@example.com');
    when(() => sampleUser.displayName).thenReturn('Test');

    credentialWithUser = MockUserCredential();
    when(() => credentialWithUser.user).thenReturn(sampleUser);

    credentialWithoutUser = MockUserCredential();
    when(() => credentialWithoutUser.user).thenReturn(null);
  });

  group('login', () {
    test('returns UserModel on success', () async {
      when(
        () => firebaseAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => credentialWithUser);

      final result = await dataSource.login(
        email: '  test@example.com ',
        password: 'secret',
      );

      expect(result.uid, 'uid-1');
      expect(result.email, 'test@example.com');
      verify(
        () => firebaseAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'secret',
        ),
      ).called(1);
    });

    test('throws AuthException when credential.user is null', () async {
      when(
        () => firebaseAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => credentialWithoutUser);

      expect(
        () => dataSource.login(email: 'a@b.com', password: 'x'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.code,
            'code',
            'user-not-found',
          ),
        ),
      );
    });

    test('maps FirebaseAuthException', () async {
      when(
        () => firebaseAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(FirebaseAuthException(code: 'wrong-password'));

      expect(
        () => dataSource.login(email: 'a@b.com', password: 'x'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.code,
            'code',
            'wrong-password',
          ),
        ),
      );
    });

    test('maps unknown errors', () async {
      when(
        () => firebaseAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(Exception('boom'));

      expect(
        () => dataSource.login(email: 'a@b.com', password: 'x'),
        throwsA(
          isA<AuthException>().having((e) => e.code, 'code', 'unknown'),
        ),
      );
    });
  });

  group('signup', () {
    test('returns UserModel on success', () async {
      when(
        () => firebaseAuth.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => credentialWithUser);

      final result = await dataSource.signup(
        email: '  new@example.com ',
        password: 'secret',
      );

      expect(result.uid, 'uid-1');
      verify(
        () => firebaseAuth.createUserWithEmailAndPassword(
          email: 'new@example.com',
          password: 'secret',
        ),
      ).called(1);
    });

    test('throws when user is null', () async {
      when(
        () => firebaseAuth.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => credentialWithoutUser);

      expect(
        () => dataSource.signup(email: 'a@b.com', password: 'x'),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', 'unknown')),
      );
    });

    test('maps FirebaseAuthException', () async {
      when(
        () => firebaseAuth.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

      expect(
        () => dataSource.signup(email: 'a@b.com', password: 'x'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.code,
            'code',
            'email-already-in-use',
          ),
        ),
      );
    });

    test('maps unknown errors', () async {
      when(
        () => firebaseAuth.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(StateError('fail'));

      expect(
        () => dataSource.signup(email: 'a@b.com', password: 'x'),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', 'unknown')),
      );
    });
  });

  group('logout', () {
    test('completes on success', () async {
      when(() => firebaseAuth.signOut()).thenAnswer((_) async {});

      await expectLater(dataSource.logout(), completes);
    });

    test('maps FirebaseAuthException', () async {
      when(
        () => firebaseAuth.signOut(),
      ).thenThrow(FirebaseAuthException(code: 'network-request-failed'));

      expect(
        () => dataSource.logout(),
        throwsA(
          isA<AuthException>().having(
            (e) => e.code,
            'code',
            'network-request-failed',
          ),
        ),
      );
    });

    test('maps unknown errors', () async {
      when(() => firebaseAuth.signOut()).thenThrow(Exception('x'));

      expect(
        () => dataSource.logout(),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', 'unknown')),
      );
    });
  });

  group('getCurrentUser', () {
    test('returns null when signed out', () async {
      when(() => firebaseAuth.currentUser).thenReturn(null);
      expect(await dataSource.getCurrentUser(), isNull);
    });

    test('returns mapped user when signed in', () async {
      when(() => firebaseAuth.currentUser).thenReturn(sampleUser);
      final result = await dataSource.getCurrentUser();
      expect(result?.uid, 'uid-1');
    });
  });

  group('authStateChanges', () {
    test('maps null and non-null users', () async {
      when(() => firebaseAuth.authStateChanges()).thenAnswer(
        (_) => Stream.fromIterable([null, sampleUser]),
      );

      final events = await dataSource.authStateChanges().toList();
      expect(events[0], isNull);
      expect(events[1]?.uid, 'uid-1');
    });
  });
}
