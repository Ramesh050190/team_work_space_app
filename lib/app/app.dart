import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:team_workspace/app/config/app_config.dart';
import 'package:team_workspace/app/theme/app_theme.dart';
import 'package:team_workspace/core/di/app_di.dart';
import 'package:team_workspace/core/localization/locale_cubit.dart';
import 'package:team_workspace/core/theme/app_theme_cubit.dart';
import 'package:team_workspace/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:team_workspace/features/authentication/presentation/bloc/auth_state.dart';
import 'package:team_workspace/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:team_workspace/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:team_workspace/features/task/presentation/bloc/sync/sync_bloc.dart';
import 'package:team_workspace/features/task/presentation/bloc/sync/sync_event.dart';
import 'package:team_workspace/l10n/app_localizations.dart';

class TeamWorkspaceApp extends StatelessWidget {
  const TeamWorkspaceApp({
    super.key,
    required this.appConfig,
    required this.router,
  });

  final AppConfig appConfig;
  final GoRouter router;

  void _resetSessionUi(BuildContext context) {
    context.read<DashboardBloc>().add(const ResetDashboard());
    context.read<SyncBloc>().add(const ResetSyncSession());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: sl<AuthBloc>()),
        BlocProvider<DashboardBloc>.value(value: sl<DashboardBloc>()),
        BlocProvider<LocaleCubit>.value(value: sl<LocaleCubit>()),
        BlocProvider<AppThemeCubit>.value(value: sl<AppThemeCubit>()),
        BlocProvider<SyncBloc>.value(
          value: sl<SyncBloc>()..add(const SyncStartedListening()),
        ),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) {
          if (current is AuthUnauthenticated || current is AuthFailure) {
            return previous is AuthAuthenticated || previous is AuthLoading;
          }
          if (current is AuthAuthenticated) {
            if (previous is AuthAuthenticated) {
              return previous.user.uid != current.user.uid;
            }
            // Login / signup / cold-start session restore.
            return previous is AuthLoading ||
                previous is AuthUnauthenticated ||
                previous is AuthFailure ||
                previous is AuthInitial;
          }
          return false;
        },
        listener: (context, state) => _resetSessionUi(context),
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          builder: (context, child) {
            return BlocBuilder<LocaleCubit, Locale>(
              builder: (context, locale) {
                return BlocBuilder<AppThemeCubit, ThemeMode>(
                  builder: (context, themeMode) {
                    return MaterialApp.router(
                      title: appConfig.appName,
                      debugShowCheckedModeBanner: appConfig.isDevelopment,
                      theme: AppTheme.light,
                      darkTheme: AppTheme.dark,
                      themeMode: themeMode,
                      locale: locale,
                      supportedLocales: AppLocalizations.supportedLocales,
                      localizationsDelegates: const [
                        AppLocalizations.delegate,
                        GlobalMaterialLocalizations.delegate,
                        GlobalWidgetsLocalizations.delegate,
                        GlobalCupertinoLocalizations.delegate,
                      ],
                      routerConfig: router,
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
