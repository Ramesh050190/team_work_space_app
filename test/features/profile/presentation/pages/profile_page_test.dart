import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/core/localization/locale_cubit.dart';
import 'package:team_workspace/core/theme/app_theme_cubit.dart';
import 'package:team_workspace/features/authentication/domain/entities/app_user.dart';
import 'package:team_workspace/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:team_workspace/features/authentication/presentation/bloc/auth_event.dart';
import 'package:team_workspace/features/authentication/presentation/bloc/auth_state.dart';
import 'package:team_workspace/features/profile/presentation/pages/profile_page.dart';

import '../../../../helpers/mocks.dart';
import '../../../../helpers/pump_with_l10n.dart';

void main() {
  late MockAuthBloc authBloc;
  late MockThemeCubit themeCubit;
  late MockLocaleCubit localeCubit;

  setUpAll(() {
    registerFallbackValue(ThemeMode.system);
    registerFallbackValue(const Locale('en'));
    registerFallbackValue(const AuthLogoutRequested());
  });

  setUp(() {
    authBloc = MockAuthBloc();
    themeCubit = MockThemeCubit();
    localeCubit = MockLocaleCubit();
    when(() => themeCubit.state).thenReturn(ThemeMode.system);
    whenListen(
      themeCubit,
      Stream<ThemeMode>.empty(),
      initialState: ThemeMode.system,
    );
    when(() => localeCubit.state).thenReturn(AppLocales.english);
    whenListen(
      localeCubit,
      Stream<Locale>.empty(),
      initialState: AppLocales.english,
    );
    when(() => themeCubit.setThemeMode(any())).thenAnswer((_) async {});
    when(() => localeCubit.setLocale(any())).thenAnswer((_) async {});
  });

  Widget pumpProfile({AuthState authState = const AuthUnauthenticated()}) {
    when(() => authBloc.state).thenReturn(authState);
    whenListen(authBloc, Stream<AuthState>.empty(), initialState: authState);

    return pumpWithL10n(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<AppThemeCubit>.value(value: themeCubit),
          BlocProvider<LocaleCubit>.value(value: localeCubit),
        ],
        child: const ProfilePage(),
      ),
    );
  }

  testWidgets('shows displayName and email when authenticated', (tester) async {
    const user = AppUser(
      uid: 'u1',
      email: 'ada@example.com',
      displayName: 'Ada Lovelace',
    );

    await tester.pumpWidget(
      pumpProfile(authState: const AuthAuthenticated(user)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('ada@example.com'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('falls back to email local-part without displayName', (
    tester,
  ) async {
    const user = AppUser(uid: 'u1', email: 'ada@example.com');

    await tester.pumpWidget(
      pumpProfile(authState: const AuthAuthenticated(user)),
    );
    await tester.pumpAndSettle();

    expect(find.text('ada'), findsOneWidget);
  });

  testWidgets('unauthenticated header uses profile title', (tester) async {
    await tester.pumpWidget(pumpProfile());
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsWidgets);
    expect(find.text('P'), findsOneWidget);
  });

  testWidgets('theme and language changes and logout', (tester) async {
    await tester.pumpWidget(pumpProfile());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Light'));
    await tester.pump();
    verify(() => themeCubit.setThemeMode(ThemeMode.light)).called(1);

    await tester.tap(find.text('Hindi'));
    await tester.pump();
    verify(() => localeCubit.setLocale(AppLocales.hindi)).called(1);

    await tester.tap(find.text('Logout'));
    await tester.pump();
    verify(() => authBloc.add(const AuthLogoutRequested())).called(1);
  });
}
