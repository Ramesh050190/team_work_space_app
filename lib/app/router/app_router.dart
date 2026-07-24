import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:team_workspace/app/router/go_router_refresh_stream.dart';
import 'package:team_workspace/core/constants/route_constants.dart';
import 'package:team_workspace/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:team_workspace/features/authentication/presentation/bloc/auth_state.dart';
import 'package:team_workspace/features/authentication/presentation/pages/login_page.dart';
import 'package:team_workspace/features/authentication/presentation/pages/signup_page.dart';
import 'package:team_workspace/features/authentication/presentation/pages/splash_page.dart';
import 'package:team_workspace/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:team_workspace/features/profile/presentation/pages/profile_page.dart';
import 'package:team_workspace/features/task/presentation/pages/create_task_page.dart';
import 'package:team_workspace/features/task/presentation/pages/edit_task_page.dart';
import 'package:team_workspace/features/task/presentation/pages/task_details_page.dart';

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static GoRouter createRouter(AuthBloc authBloc) {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: RouteConstants.splash,
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) => _redirect(authBloc.state, state),
      routes: [
        GoRoute(
          path: RouteConstants.splash,
          name: 'splash',
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: RouteConstants.login,
          name: 'login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: RouteConstants.signup,
          name: 'signup',
          builder: (context, state) => const SignupPage(),
        ),
        GoRoute(
          path: RouteConstants.dashboard,
          name: 'dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: RouteConstants.profile,
          name: 'profile',
          builder: (context, state) => const ProfilePage(),
        ),
        GoRoute(
          path: RouteConstants.createTask,
          name: 'createTask',
          builder: (context, state) => const CreateTaskPage(),
        ),
        GoRoute(
          path: RouteConstants.editTask,
          name: 'editTask',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return EditTaskPage(taskId: id);
          },
        ),
        GoRoute(
          path: RouteConstants.taskDetails,
          name: 'taskDetails',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return TaskDetailsPage(taskId: id);
          },
        ),
      ],
    );
  }

  static String? _redirect(AuthState authState, GoRouterState state) {
    final location = state.matchedLocation;
    final isSplash = location == RouteConstants.splash;
    final isAuthRoute =
        location == RouteConstants.login || location == RouteConstants.signup;
    final isProtected =
        location == RouteConstants.dashboard ||
        location == RouteConstants.profile ||
        location.startsWith('/tasks');

    // Cold start: hold on splash until the first session check runs.
    if (authState is AuthInitial) {
      return isSplash ? null : RouteConstants.splash;
    }

    // While login/signup/logout/session-check is in flight, do NOT bounce
    // routes. Redirecting AuthLoading → splash remounts SplashPage, which
    // re-dispatches AuthCheckRequested and can flash login mid-success.
    if (authState is AuthLoading) {
      return null;
    }

    if (authState is AuthAuthenticated) {
      if (isSplash || isAuthRoute) {
        return RouteConstants.dashboard;
      }
      return null;
    }

    if (authState is AuthUnauthenticated || authState is AuthFailure) {
      if (isProtected || isSplash) {
        return RouteConstants.login;
      }
      return null;
    }

    return null;
  }
}
