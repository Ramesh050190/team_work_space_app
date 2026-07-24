import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:team_workspace/app/app.dart';
import 'package:team_workspace/app/config/app_config.dart';
import 'package:team_workspace/app/router/app_router.dart';
import 'package:team_workspace/core/di/app_di.dart';
import 'package:team_workspace/core/logger/app_logger.dart';
import 'package:team_workspace/core/storage/hive_service.dart';
import 'package:team_workspace/features/authentication/presentation/bloc/auth_bloc.dart';

/// Shared startup used by all flavor entry points (`main_*.dart`).
Future<void> bootstrap(AppConfig appConfig) async {
  WidgetsFlutterBinding.ensureInitialized();

  final logger = AppLogger();
  logger.info('Starting flavor=${appConfig.flavor} (${appConfig.appName})');

  try {
    await Firebase.initializeApp();
    logger.info('Firebase initialized');
  } catch (e, st) {
    logger.warning('Firebase initialization skipped or failed', e, st);
  }

  await configureDependencies(appConfig: appConfig);
  await sl<HiveService>().init();

  final authBloc = sl<AuthBloc>();
  final router = AppRouter.createRouter(authBloc);

  runApp(TeamWorkspaceApp(appConfig: appConfig, router: router));
}
