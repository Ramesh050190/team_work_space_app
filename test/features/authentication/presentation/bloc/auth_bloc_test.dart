import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/core/errors/authentication_failure.dart';
import 'package:team_workspace/features/authentication/domain/entities/app_user.dart';
import 'package:team_workspace/features/authentication/domain/usecases/get_current_user_usecase.dart';
import 'package:team_workspace/features/authentication/domain/usecases/login_usecase.dart';
import 'package:team_workspace/features/authentication/domain/usecases/logout_usecase.dart';
import 'package:team_workspace/features/authentication/domain/usecases/signup_usecase.dart';
import 'package:team_workspace/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:team_workspace/features/authentication/presentation/bloc/auth_event.dart';
import 'package:team_workspace/features/authentication/presentation/bloc/auth_state.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockSignupUseCase extends Mock implements SignupUseCase {}

class MockLogoutUseCase extends Mock implements LogoutUseCase {}

class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}

void main() {
  late MockLoginUseCase loginUseCase;
  late MockSignupUseCase signupUseCase;
  late MockLogoutUseCase logoutUseCase;
  late MockGetCurrentUserUseCase getCurrentUserUseCase;
  late StreamController<AppUser?> authStateController;

  const tUser = AppUser(uid: 'uid-1', email: 'test@example.com');

  AuthBloc buildBloc() {
    return AuthBloc(
      loginUseCase: loginUseCase,
      signupUseCase: signupUseCase,
      logoutUseCase: logoutUseCase,
      getCurrentUserUseCase: getCurrentUserUseCase,
    );
  }

  setUp(() {
    loginUseCase = MockLoginUseCase();
    signupUseCase = MockSignupUseCase();
    logoutUseCase = MockLogoutUseCase();
    getCurrentUserUseCase = MockGetCurrentUserUseCase();
    authStateController = StreamController<AppUser?>.broadcast();

    when(
      () => getCurrentUserUseCase.watchAuthState(),
    ).thenAnswer((_) => authStateController.stream);
  });

  tearDown(() async {
    await authStateController.close();
  });

  test('initial state is AuthInitial', () {
    expect(buildBloc().state, const AuthInitial());
  });

  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, AuthAuthenticated] when AuthCheckRequested finds a user',
    build: buildBloc,
    setUp: () {
      when(
        () => getCurrentUserUseCase(),
      ).thenAnswer((_) async => const Right(tUser));
    },
    act: (bloc) => bloc.add(const AuthCheckRequested()),
    expect: () => [const AuthLoading(), const AuthAuthenticated(tUser)],
  );

  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, AuthUnauthenticated] when AuthCheckRequested finds no user',
    build: buildBloc,
    setUp: () {
      when(
        () => getCurrentUserUseCase(),
      ).thenAnswer((_) async => const Right(null));
    },
    act: (bloc) => bloc.add(const AuthCheckRequested()),
    expect: () => [const AuthLoading(), const AuthUnauthenticated()],
  );

  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, AuthAuthenticated] on successful login',
    build: buildBloc,
    setUp: () {
      when(
        () => loginUseCase(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Right(tUser));
    },
    act: (bloc) => bloc.add(
      const AuthLoginRequested(
        email: 'test@example.com',
        password: 'password123',
      ),
    ),
    expect: () => [const AuthLoading(), const AuthAuthenticated(tUser)],
  );

  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, AuthFailure] on failed login',
    build: buildBloc,
    setUp: () {
      when(
        () => loginUseCase(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async =>
            const Left(AuthenticationFailure(message: 'Incorrect password.')),
      );
    },
    act: (bloc) => bloc.add(
      const AuthLoginRequested(email: 'test@example.com', password: 'wrong'),
    ),
    expect: () => [
      const AuthLoading(),
      const AuthFailure('Incorrect password.'),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, AuthAuthenticated] on successful signup',
    build: buildBloc,
    setUp: () {
      when(
        () => signupUseCase(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Right(tUser));
    },
    act: (bloc) => bloc.add(
      const AuthSignupRequested(
        email: 'test@example.com',
        password: 'password123',
      ),
    ),
    expect: () => [const AuthLoading(), const AuthAuthenticated(tUser)],
  );

  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, AuthUnauthenticated] on successful logout',
    build: buildBloc,
    seed: () => const AuthAuthenticated(tUser),
    setUp: () {
      when(() => logoutUseCase()).thenAnswer((_) async => const Right(null));
    },
    act: (bloc) => bloc.add(const AuthLogoutRequested()),
    expect: () => [const AuthLoading(), const AuthUnauthenticated()],
  );

  blocTest<AuthBloc, AuthState>(
    'emits AuthUnauthenticated when AuthErrorReset is added',
    build: buildBloc,
    seed: () => const AuthFailure('Something went wrong'),
    act: (bloc) => bloc.add(const AuthErrorReset()),
    expect: () => [const AuthUnauthenticated()],
  );

  blocTest<AuthBloc, AuthState>(
    'updates to AuthAuthenticated when auth state stream emits a user',
    build: buildBloc,
    act: (bloc) async {
      authStateController.add(tUser);
      await Future<void>.delayed(Duration.zero);
    },
    expect: () => [const AuthAuthenticated(tUser)],
  );
}
