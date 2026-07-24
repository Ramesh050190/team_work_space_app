import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/core/localization/locale_cubit.dart';
import 'package:team_workspace/core/theme/app_theme_cubit.dart';
import 'package:team_workspace/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:team_workspace/features/authentication/presentation/bloc/auth_state.dart';
import 'package:team_workspace/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:team_workspace/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:team_workspace/features/task/presentation/bloc/sync/sync_bloc.dart';
import 'package:team_workspace/features/task/presentation/bloc/sync/sync_state.dart';
import 'package:team_workspace/l10n/app_localizations.dart';

import 'fixtures.dart';
import 'mocks.dart';

export 'fixtures.dart';
export 'mocks.dart';
export 'pump_with_l10n.dart';

/// Shared registerFallbackValue calls for mocktail.
void registerCommonFallbackValues() {
  registerFallbackValue(FakeData.task());
  registerFallbackValue(FakeData.paginatedTasks());
  registerFallbackValue(const Locale('en'));
  registerFallbackValue(ThemeMode.system);
}

/// Wraps [child] with localization + optional blocs for page/widget tests.
Widget buildTestApp({
  required Widget child,
  AuthBloc? authBloc,
  DashboardBloc? dashboardBloc,
  SyncBloc? syncBloc,
  LocaleCubit? localeCubit,
  AppThemeCubit? themeCubit,
  List<GoRoute>? extraRoutes,
}) {
  Widget tree = child;

  final providers = <BlocProvider>[
    if (authBloc != null) BlocProvider<AuthBloc>.value(value: authBloc),
    if (dashboardBloc != null)
      BlocProvider<DashboardBloc>.value(value: dashboardBloc),
    if (syncBloc != null) BlocProvider<SyncBloc>.value(value: syncBloc),
    if (localeCubit != null)
      BlocProvider<LocaleCubit>.value(value: localeCubit),
    if (themeCubit != null) BlocProvider<AppThemeCubit>.value(value: themeCubit),
  ];

  if (providers.isNotEmpty) {
    tree = MultiBlocProvider(providers: providers, child: tree);
  }

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => tree),
      GoRoute(
        path: '/login',
        builder: (context, state) => const Scaffold(body: Text('login')),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const Scaffold(body: Text('signup')),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const Scaffold(body: Text('dashboard')),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const Scaffold(body: Text('profile')),
      ),
      GoRoute(
        path: '/tasks/create',
        builder: (context, state) => const Scaffold(body: Text('create')),
      ),
      ...?extraRoutes,
    ],
  );

  return MaterialApp.router(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    routerConfig: router,
  );
}

/// Stub AuthBloc that starts in [state].
MockAuthBloc stubAuthBloc([AuthState state = const AuthInitial()]) {
  final bloc = MockAuthBloc();
  when(() => bloc.state).thenReturn(state);
  when(() => bloc.stream).thenAnswer((_) => Stream.value(state));
  return bloc;
}

/// Stub DashboardBloc that starts in [state].
MockDashboardBloc stubDashboardBloc([
  DashboardState state = const DashboardInitial(),
]) {
  final bloc = MockDashboardBloc();
  when(() => bloc.state).thenReturn(state);
  when(() => bloc.stream).thenAnswer((_) => Stream.value(state));
  return bloc;
}

/// Stub SyncBloc that starts in [state].
MockSyncBloc stubSyncBloc([SyncState state = const SyncInitial()]) {
  final bloc = MockSyncBloc();
  when(() => bloc.state).thenReturn(state);
  when(() => bloc.stream).thenAnswer((_) => Stream.value(state));
  return bloc;
}
