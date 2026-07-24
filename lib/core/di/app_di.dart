import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:team_workspace/app/config/app_config.dart';
import 'package:team_workspace/core/connectivity/connectivity_service.dart';
import 'package:team_workspace/core/localization/locale_cubit.dart';
import 'package:team_workspace/core/logger/app_logger.dart';
import 'package:team_workspace/core/network/api_client.dart';
import 'package:team_workspace/core/network/network_info.dart';
import 'package:team_workspace/core/storage/hive_service.dart';
import 'package:team_workspace/core/sync/sync_manager.dart';
import 'package:team_workspace/core/theme/app_theme_cubit.dart';
import 'package:team_workspace/features/authentication/data/datasources/auth_local_datasource.dart';
import 'package:team_workspace/features/authentication/data/datasources/auth_local_datasource_impl.dart';
import 'package:team_workspace/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:team_workspace/features/authentication/data/datasources/auth_remote_datasource_impl.dart';
import 'package:team_workspace/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:team_workspace/features/authentication/domain/repositories/auth_repository.dart';
import 'package:team_workspace/features/authentication/domain/usecases/get_current_user_usecase.dart';
import 'package:team_workspace/features/authentication/domain/usecases/login_usecase.dart';
import 'package:team_workspace/features/authentication/domain/usecases/logout_usecase.dart';
import 'package:team_workspace/features/authentication/domain/usecases/signup_usecase.dart';
import 'package:team_workspace/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:team_workspace/features/dashboard/data/datasources/dashboard_local_datasource.dart';
import 'package:team_workspace/features/dashboard/data/datasources/dashboard_local_datasource_impl.dart';
import 'package:team_workspace/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:team_workspace/features/dashboard/data/datasources/dashboard_remote_datasource_impl.dart';
import 'package:team_workspace/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:team_workspace/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:team_workspace/features/dashboard/domain/usecases/get_tasks_usecase.dart';
import 'package:team_workspace/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:team_workspace/features/task/data/datasources/task_local_datasource.dart';
import 'package:team_workspace/features/task/data/datasources/task_local_datasource_impl.dart';
import 'package:team_workspace/features/task/data/datasources/task_remote_datasource.dart';
import 'package:team_workspace/features/task/data/datasources/task_remote_datasource_impl.dart';
import 'package:team_workspace/features/task/data/repositories/task_repository_impl.dart';
import 'package:team_workspace/features/task/domain/repositories/task_repository.dart';
import 'package:team_workspace/features/task/domain/usecases/create_task_usecase.dart';
import 'package:team_workspace/features/task/domain/usecases/get_task_details_usecase.dart';
import 'package:team_workspace/features/task/domain/usecases/sync_pending_changes_usecase.dart';
import 'package:team_workspace/features/task/domain/usecases/update_task_status_usecase.dart';
import 'package:team_workspace/features/task/domain/usecases/update_task_usecase.dart';
import 'package:team_workspace/features/task/presentation/bloc/sync/sync_bloc.dart';
import 'package:team_workspace/features/task/presentation/bloc/task_details_bloc.dart';
import 'package:team_workspace/features/task/presentation/bloc/task_form/task_form_bloc.dart';

final GetIt sl = GetIt.instance;

Future<void> configureDependencies({required AppConfig appConfig}) async {
  /// Core
  sl.registerLazySingleton<AppConfig>(() => appConfig);
  sl.registerLazySingleton<AppLogger>(() => AppLogger());

  sl.registerLazySingleton<Connectivity>(() => Connectivity());

  sl.registerLazySingleton<ConnectivityService>(
    () => ConnectivityService(connectivity: sl()),
  );

  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(connectivityService: sl()),
  );

  sl.registerLazySingleton<HiveService>(() => HiveService(logger: sl()));

  final baseUrl = appConfig.apiBaseUrl;

  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(
      baseUrl: baseUrl,
      logger: sl(),
      enableTaskMock: appConfig.useTaskMock,
    ),
  );

  sl.registerLazySingleton<Dio>(() => sl<ApiClient>().dio);

  /// External : Fire base
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);

  /// Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(firebaseAuth: sl()),
  );

  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(hiveService: sl()),
  );

  sl.registerLazySingleton<TaskRemoteDataSource>(
    () => TaskRemoteDataSourceImpl(dio: sl()),
  );

  sl.registerLazySingleton<TaskLocalDataSource>(
    () => TaskLocalDataSourceImpl(hiveService: sl()),
  );

  sl.registerLazySingleton<DashboardRemoteDataSource>(
    () => DashboardRemoteDataSourceImpl(dio: sl()),
  );

  sl.registerLazySingleton<DashboardLocalDataSource>(
    () => DashboardLocalDataSourceImpl(taskLocalDataSource: sl()),
  );

  /// Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      taskLocalDataSource: sl(),
    ),
  );

  sl.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  /// Sync
  sl.registerLazySingleton(
    () => SyncManager(
      remoteDataSource: sl(),
      localDataSource: sl(),
      connectivityService: sl(),
      logger: sl(),
    ),
  );

  /// Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => SignupUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));

  sl.registerLazySingleton(() => GetTaskDetailsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateTaskStatusUseCase(sl()));
  sl.registerLazySingleton(() => CreateTaskUseCase(sl()));
  sl.registerLazySingleton(() => UpdateTaskUseCase(sl()));
  sl.registerLazySingleton(() => GetTasksUseCase(sl()));
  sl.registerLazySingleton(() => SyncPendingChangesUseCase(sl()));

  /// Blocs
  sl.registerLazySingleton(
    () => AuthBloc(
      loginUseCase: sl(),
      signupUseCase: sl(),
      logoutUseCase: sl(),
      getCurrentUserUseCase: sl(),
    ),
  );

  sl.registerLazySingleton(() => DashboardBloc(getTasksUseCase: sl()));

  sl.registerLazySingleton(
    () => SyncBloc(
      syncManager: sl(),
      syncPendingChangesUseCase: sl(),
      connectivityService: sl(),
      localDataSource: sl(),
    ),
  );

  sl.registerLazySingleton(() => LocaleCubit(hiveService: sl()));

  sl.registerLazySingleton(() => AppThemeCubit(hiveService: sl()));

  sl.registerFactoryParam<TaskDetailsBloc, int, void>(
    (taskId, _) => TaskDetailsBloc(
      getTaskDetailsUseCase: sl(),
      updateTaskStatusUseCase: sl(),
      taskId: taskId,
      taskLocalDataSource: sl(),
    ),
  );

  sl.registerFactory(
    () => TaskFormBloc(createTaskUseCase: sl(), updateTaskUseCase: sl()),
  );
}
