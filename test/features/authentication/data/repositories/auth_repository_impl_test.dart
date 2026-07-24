import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/core/errors/authentication_failure.dart';
import 'package:team_workspace/core/errors/network_failure.dart';
import 'package:team_workspace/core/errors/server_failure.dart';
import 'package:team_workspace/features/authentication/data/datasources/auth_local_datasource.dart';
import 'package:team_workspace/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:team_workspace/features/authentication/data/exceptions/auth_exception.dart';
import 'package:team_workspace/features/authentication/data/models/user_model.dart';
import 'package:team_workspace/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:team_workspace/features/authentication/domain/entities/app_user.dart';
import 'package:team_workspace/features/task/data/datasources/task_local_datasource.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

class MockTaskLocalDataSource extends Mock implements TaskLocalDataSource {}

void main() {
  late MockAuthRemoteDataSource remoteDataSource;
  late MockAuthLocalDataSource localDataSource;
  late MockTaskLocalDataSource taskLocalDataSource;
  late AuthRepositoryImpl repository;

  const tUserModel = UserModel(
    uid: 'uid-1',
    email: 'test@example.com',
    displayName: 'Test User',
  );

  const tOtherUser = UserModel(
    uid: 'uid-2',
    email: 'other@example.com',
    displayName: 'Other User',
  );

  const tAppUser = AppUser(
    uid: 'uid-1',
    email: 'test@example.com',
    displayName: 'Test User',
  );

  setUpAll(() {
    registerFallbackValue(tUserModel);
  });

  setUp(() {
    remoteDataSource = MockAuthRemoteDataSource();
    localDataSource = MockAuthLocalDataSource();
    taskLocalDataSource = MockTaskLocalDataSource();
    when(() => localDataSource.cacheUser(any())).thenAnswer((_) async {});
    when(() => localDataSource.clearCachedUser()).thenAnswer((_) async {});
    when(() => localDataSource.getCachedUser()).thenAnswer((_) async => null);
    when(
      () => localDataSource.getLastSessionUid(),
    ).thenAnswer((_) async => null);
    when(
      () => taskLocalDataSource.clearAllTaskCache(),
    ).thenAnswer((_) async {});
    repository = AuthRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
      taskLocalDataSource: taskLocalDataSource,
    );
  });

  group('login', () {
    test('returns AppUser when remote login succeeds', () async {
      when(
        () => remoteDataSource.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => tUserModel);

      final result = await repository.login(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result, const Right(tAppUser));
      verify(
        () => remoteDataSource.login(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).called(1);
      verifyNever(() => taskLocalDataSource.clearAllTaskCache());
      verify(() => localDataSource.cacheUser(tUserModel)).called(1);
    });

    test('clears task cache when a different user logs in', () async {
      when(
        () => localDataSource.getCachedUser(),
      ).thenAnswer((_) async => tOtherUser);
      when(
        () => remoteDataSource.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => tUserModel);

      final result = await repository.login(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result, const Right(tAppUser));
      verify(() => taskLocalDataSource.clearAllTaskCache()).called(1);
      verify(() => localDataSource.cacheUser(tUserModel)).called(1);
    });

    test(
      'clears task cache when last session uid differs after logout',
      () async {
        when(
          () => localDataSource.getCachedUser(),
        ).thenAnswer((_) async => null);
        when(
          () => localDataSource.getLastSessionUid(),
        ).thenAnswer((_) async => tOtherUser.uid);
        when(
          () => remoteDataSource.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => tUserModel);

        await repository.login(
          email: 'test@example.com',
          password: 'password123',
        );

        verify(() => taskLocalDataSource.clearAllTaskCache()).called(1);
      },
    );

    test('keeps task cache when the same user logs in again', () async {
      when(
        () => localDataSource.getCachedUser(),
      ).thenAnswer((_) async => tUserModel);
      when(
        () => remoteDataSource.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => tUserModel);

      await repository.login(
        email: 'test@example.com',
        password: 'password123',
      );

      verifyNever(() => taskLocalDataSource.clearAllTaskCache());
    });

    test('keeps task cache when same user logs in after logout', () async {
      when(() => localDataSource.getCachedUser()).thenAnswer((_) async => null);
      when(
        () => localDataSource.getLastSessionUid(),
      ).thenAnswer((_) async => tUserModel.uid);
      when(
        () => remoteDataSource.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => tUserModel);

      await repository.login(
        email: 'test@example.com',
        password: 'password123',
      );

      verifyNever(() => taskLocalDataSource.clearAllTaskCache());
    });

    test('returns AuthenticationFailure for auth exceptions', () async {
      when(
        () => remoteDataSource.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        const AuthException(
          code: 'wrong-password',
          message: 'Incorrect password.',
        ),
      );

      final result = await repository.login(
        email: 'test@example.com',
        password: 'wrong',
      );

      expect(
        result,
        const Left(AuthenticationFailure(message: 'Incorrect password.')),
      );
    });

    test('returns NetworkFailure for network auth exceptions', () async {
      when(
        () => remoteDataSource.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        const AuthException(
          code: 'network-request-failed',
          message: 'Network error.',
        ),
      );

      final result = await repository.login(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result, const Left(NetworkFailure(message: 'Network error.')));
    });

    test('returns ServerFailure for unknown errors', () async {
      when(
        () => remoteDataSource.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(Exception('unexpected'));

      final result = await repository.login(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(
        result,
        const Left(
          ServerFailure(message: 'Something went wrong. Please try again.'),
        ),
      );
    });
  });

  group('signup', () {
    test('returns AppUser when remote signup succeeds', () async {
      when(
        () => remoteDataSource.signup(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => tUserModel);

      final result = await repository.signup(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result, const Right(tAppUser));
      verifyNever(() => taskLocalDataSource.clearAllTaskCache());
      verify(() => localDataSource.cacheUser(tUserModel)).called(1);
    });

    test('clears task cache when signup is for a different account', () async {
      when(
        () => localDataSource.getLastSessionUid(),
      ).thenAnswer((_) async => tOtherUser.uid);
      when(
        () => remoteDataSource.signup(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => tUserModel);

      await repository.signup(
        email: 'test@example.com',
        password: 'password123',
      );

      verify(() => taskLocalDataSource.clearAllTaskCache()).called(1);
    });

    test('returns AuthenticationFailure for signup AuthException', () async {
      when(
        () => remoteDataSource.signup(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        const AuthException(
          code: 'email-already-in-use',
          message: 'Email already in use.',
        ),
      );

      final result = await repository.signup(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(
        result,
        const Left(AuthenticationFailure(message: 'Email already in use.')),
      );
    });
  });

  group('logout', () {
    test(
      'clears cached user but keeps task cache for same-user re-login',
      () async {
        when(() => remoteDataSource.logout()).thenAnswer((_) async {});

        final result = await repository.logout();

        expect(result, const Right(null));
        verifyNever(() => taskLocalDataSource.clearAllTaskCache());
        verify(() => localDataSource.clearCachedUser()).called(1);
      },
    );

    test('returns AuthenticationFailure for logout AuthException', () async {
      when(() => remoteDataSource.logout()).thenThrow(
        const AuthException(
          code: 'too-many-requests',
          message: 'Too many requests.',
        ),
      );

      final result = await repository.logout();

      expect(
        result,
        const Left(AuthenticationFailure(message: 'Too many requests.')),
      );
    });
  });

  group('currentUser', () {
    test('returns AppUser when a session exists', () async {
      when(
        () => remoteDataSource.getCurrentUser(),
      ).thenAnswer((_) async => tUserModel);

      final result = await repository.currentUser();

      expect(result, const Right(tAppUser));
    });

    test('returns null when no session exists', () async {
      when(
        () => remoteDataSource.getCurrentUser(),
      ).thenAnswer((_) async => null);

      final result = await repository.currentUser();

      expect(result, const Right(null));
    });

    test('falls back to cache when AuthException is thrown', () async {
      when(() => remoteDataSource.getCurrentUser()).thenThrow(
        const AuthException(
          code: 'network-request-failed',
          message: 'Network error.',
        ),
      );
      when(
        () => localDataSource.getCachedUser(),
      ).thenAnswer((_) async => tUserModel);

      final result = await repository.currentUser();

      expect(result, const Right(tAppUser));
    });
  });

  group('authStateChanges', () {
    test('emits user then null', () async {
      when(
        () => remoteDataSource.authStateChanges(),
      ).thenAnswer((_) => Stream.fromIterable([tUserModel, null]));

      await expectLater(
        repository.authStateChanges(),
        emitsInOrder([tAppUser, null]),
      );

      verify(() => localDataSource.cacheUser(tUserModel)).called(1);
      verify(() => localDataSource.clearCachedUser()).called(1);
    });
  });
}
