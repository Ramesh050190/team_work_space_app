import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/core/constants/app_constants.dart';
import 'package:team_workspace/features/authentication/domain/entities/app_user.dart';
import 'package:team_workspace/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:team_workspace/features/authentication/presentation/bloc/auth_event.dart';
import 'package:team_workspace/features/authentication/presentation/bloc/auth_state.dart';
import 'package:team_workspace/features/authentication/presentation/pages/splash_page.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockAuthBloc authBloc;

  setUpAll(() {
    registerFallbackValue(const AuthCheckRequested());
  });

  setUp(() {
    authBloc = MockAuthBloc();
  });

  Widget pumpSplash() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: const SplashPage(),
      ),
    );
  }

  testWidgets('renders branding and spinner', (tester) async {
    when(() => authBloc.state).thenReturn(const AuthInitial());
    whenListen(authBloc, Stream<AuthState>.empty(), initialState: const AuthInitial());

    await tester.pumpWidget(pumpSplash());

    expect(find.byType(FlutterLogo), findsOneWidget);
    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('dispatches AuthCheckRequested from AuthInitial', (tester) async {
    when(() => authBloc.state).thenReturn(const AuthInitial());
    whenListen(authBloc, Stream<AuthState>.empty(), initialState: const AuthInitial());

    await tester.pumpWidget(pumpSplash());

    verify(() => authBloc.add(const AuthCheckRequested())).called(1);
  });

  testWidgets('does not dispatch when not AuthInitial', (tester) async {
    const user = AppUser(uid: 'u', email: 'a@b.com');
    when(() => authBloc.state).thenReturn(const AuthAuthenticated(user));
    whenListen(
      authBloc,
      Stream<AuthState>.empty(),
      initialState: const AuthAuthenticated(user),
    );

    await tester.pumpWidget(pumpSplash());

    verifyNever(() => authBloc.add(any()));
  });
}
