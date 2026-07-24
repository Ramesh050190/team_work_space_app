import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/core/localization/locale_cubit.dart';
import 'package:team_workspace/core/theme/app_theme_cubit.dart';
import 'package:team_workspace/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:team_workspace/features/authentication/presentation/bloc/auth_event.dart';
import 'package:team_workspace/features/authentication/presentation/bloc/auth_state.dart';
import 'package:team_workspace/features/profile/presentation/pages/profile_page.dart';

import '../../../../helpers/test_helper.dart';

void main() {
  late MockAuthBloc authBloc;
  late MockThemeCubit themeCubit;
  late MockLocaleCubit localeCubit;

  setUpAll(() {
    registerCommonFallbackValues();
    registerFallbackValue(const AuthLogoutRequested());
  });

  setUp(() {
    authBloc = MockAuthBloc();
    themeCubit = MockThemeCubit();
    localeCubit = MockLocaleCubit();

    when(() => themeCubit.state).thenReturn(ThemeMode.system);
    when(
      () => themeCubit.stream,
    ).thenAnswer((_) => Stream.value(ThemeMode.system));
    when(() => themeCubit.setThemeMode(any())).thenAnswer((_) async {});

    when(() => localeCubit.state).thenReturn(AppLocales.english);
    when(
      () => localeCubit.stream,
    ).thenAnswer((_) => Stream.value(AppLocales.english));
    when(() => localeCubit.setLocale(any())).thenAnswer((_) async {});
  });

  Future<void> pumpProfile(WidgetTester tester) async {
    await tester.pumpWidget(
      pumpWithL10n(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<AppThemeCubit>.value(value: themeCubit),
            BlocProvider<LocaleCubit>.value(value: localeCubit),
          ],
          child: const ProfilePage(),
        ),
      ),
    );
  }

  testWidgets(
    'shows authenticated user and logout dispatches AuthLogoutRequested',
    (tester) async {
      when(
        () => authBloc.state,
      ).thenReturn(const AuthAuthenticated(FakeData.user));
      when(
        () => authBloc.stream,
      ).thenAnswer((_) => Stream.value(const AuthAuthenticated(FakeData.user)));
      when(() => authBloc.add(any())).thenReturn(null);

      await pumpProfile(tester);

      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      await tester.tap(find.text('Logout'));
      await tester.pump();

      verify(() => authBloc.add(const AuthLogoutRequested())).called(1);
    },
  );
}
