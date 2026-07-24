import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/features/authentication/domain/entities/app_user.dart';
import 'package:team_workspace/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:team_workspace/features/authentication/presentation/pages/signup_page.dart';

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

  Future<void> pumpSignup(WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestApp(
        child: const SignupPage(),
        authBloc: authBloc,
        localeCubit: localeCubit,
      ),
    );
    await tester.pump();
  }

  group('SignupPage', () {
    testWidgets('shows email, password, confirm password and signup button', (
      tester,
    ) async {
      await pumpSignup(tester);

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Create Account'),
        findsOneWidget,
      );
    });

    testWidgets('calls signup use case when form is valid', (tester) async {
      when(
        () => signupUseCase(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Right(FakeData.user));

      await pumpSignup(tester);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'new@test.com');
      await tester.enterText(fields.at(1), 'password12');
      await tester.enterText(fields.at(2), 'password12');
      await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
      await tester.pump();

      verify(
        () => signupUseCase(email: 'new@test.com', password: 'password12'),
      ).called(1);
      await tester.pump();
    });

    testWidgets('shows confirm password mismatch validation', (tester) async {
      await pumpSignup(tester);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'new@test.com');
      await tester.enterText(fields.at(1), 'password12');
      await tester.enterText(fields.at(2), 'different99');
      await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
      verifyNever(
        () => signupUseCase(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });
  });
}
