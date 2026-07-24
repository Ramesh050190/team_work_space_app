import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/features/authentication/domain/entities/app_user.dart';
import 'package:team_workspace/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:team_workspace/features/authentication/presentation/pages/login_page.dart';

import '../../../../helpers/test_helper.dart';

void main() {
  late MockLoginUseCase loginUseCase;
  late MockSignupUseCase signupUseCase;
  late MockLogoutUseCase logoutUseCase;
  late MockGetCurrentUserUseCase getCurrentUserUseCase;
  late StreamController<AppUser?> authStateController;
  late AuthBloc authBloc;
  late MockLocaleCubit localeCubit;

  setUpAll(() {
    registerCommonFallbackValues();
  });

  setUp(() {
    loginUseCase = MockLoginUseCase();
    signupUseCase = MockSignupUseCase();
    logoutUseCase = MockLogoutUseCase();
    getCurrentUserUseCase = MockGetCurrentUserUseCase();
    authStateController = StreamController<AppUser?>.broadcast();
    when(
      () => getCurrentUserUseCase.watchAuthState(),
    ).thenAnswer((_) => authStateController.stream);

    authBloc = AuthBloc(
      loginUseCase: loginUseCase,
      signupUseCase: signupUseCase,
      logoutUseCase: logoutUseCase,
      getCurrentUserUseCase: getCurrentUserUseCase,
    );

    localeCubit = MockLocaleCubit();
    when(() => localeCubit.state).thenReturn(const Locale('en'));
    when(
      () => localeCubit.stream,
    ).thenAnswer((_) => Stream.value(const Locale('en')));
    when(() => localeCubit.setLocale(any())).thenAnswer((_) async {});
  });

  tearDown(() async {
    await authBloc.close();
    await authStateController.close();
  });

  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestApp(
        child: const LoginPage(),
        authBloc: authBloc,
        localeCubit: localeCubit,
      ),
    );
    await tester.pump();
  }

  group('LoginPage', () {
    testWidgets('shows email, password fields and login button', (
      tester,
    ) async {
      await pumpLogin(tester);

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Login'), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);
    });

    testWidgets('shows validation errors when submitting empty form', (
      tester,
    ) async {
      await pumpLogin(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Login'));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      verifyNever(
        () => loginUseCase(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });

    testWidgets('calls login use case for valid credentials', (tester) async {
      when(
        () => loginUseCase(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Right(FakeData.user));

      await pumpLogin(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'user@test.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password12');
      await tester.tap(find.widgetWithText(FilledButton, 'Login'));
      await tester.pump();

      verify(
        () => loginUseCase(email: 'user@test.com', password: 'password12'),
      ).called(1);
      await tester.pump();
    });
  });
}
