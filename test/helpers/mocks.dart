import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/core/localization/locale_cubit.dart';
import 'package:team_workspace/core/network/network_info.dart';
import 'package:team_workspace/core/sync/sync_manager.dart';
import 'package:team_workspace/core/theme/app_theme_cubit.dart';
import 'package:team_workspace/features/authentication/domain/repositories/auth_repository.dart';
import 'package:team_workspace/features/authentication/domain/usecases/get_current_user_usecase.dart';
import 'package:team_workspace/features/authentication/domain/usecases/login_usecase.dart';
import 'package:team_workspace/features/authentication/domain/usecases/logout_usecase.dart';
import 'package:team_workspace/features/authentication/domain/usecases/signup_usecase.dart';
import 'package:team_workspace/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:team_workspace/features/authentication/presentation/bloc/auth_event.dart';
import 'package:team_workspace/features/authentication/presentation/bloc/auth_state.dart';
import 'package:team_workspace/features/dashboard/domain/usecases/get_tasks_usecase.dart';
import 'package:team_workspace/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:team_workspace/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:team_workspace/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:team_workspace/features/task/data/datasources/task_local_datasource.dart';
import 'package:team_workspace/features/task/data/datasources/task_remote_datasource.dart';
import 'package:team_workspace/features/task/domain/repositories/task_repository.dart';
import 'package:team_workspace/features/task/domain/usecases/create_task_usecase.dart';
import 'package:team_workspace/features/task/domain/usecases/get_task_details_usecase.dart';
import 'package:team_workspace/features/task/domain/usecases/update_task_status_usecase.dart';
import 'package:team_workspace/features/task/domain/usecases/update_task_usecase.dart';
import 'package:team_workspace/features/task/presentation/bloc/sync/sync_bloc.dart';
import 'package:team_workspace/features/task/presentation/bloc/sync/sync_event.dart';
import 'package:team_workspace/features/task/presentation/bloc/sync/sync_state.dart';
import 'package:team_workspace/features/task/presentation/bloc/task_details_bloc.dart';
import 'package:team_workspace/features/task/presentation/bloc/task_details_event.dart';
import 'package:team_workspace/features/task/presentation/bloc/task_details_state.dart';
import 'package:team_workspace/features/task/presentation/bloc/task_form/task_form_bloc.dart';
import 'package:team_workspace/features/task/presentation/bloc/task_form/task_form_event.dart';
import 'package:team_workspace/features/task/presentation/bloc/task_form/task_form_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockTaskRepository extends Mock implements TaskRepository {}

class MockTaskRemoteDataSource extends Mock implements TaskRemoteDataSource {}

class MockTaskLocalDataSource extends Mock implements TaskLocalDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockSyncManager extends Mock implements SyncManager {}

class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockSignupUseCase extends Mock implements SignupUseCase {}

class MockLogoutUseCase extends Mock implements LogoutUseCase {}

class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}

class MockGetTasksUseCase extends Mock implements GetTasksUseCase {}

class MockCreateTaskUseCase extends Mock implements CreateTaskUseCase {}

class MockUpdateTaskUseCase extends Mock implements UpdateTaskUseCase {}

class MockGetTaskDetailsUseCase extends Mock implements GetTaskDetailsUseCase {}

class MockUpdateTaskStatusUseCase extends Mock
    implements UpdateTaskStatusUseCase {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockDashboardBloc extends MockBloc<DashboardEvent, DashboardState>
    implements DashboardBloc {}

class MockSyncBloc extends MockBloc<SyncEvent, SyncState> implements SyncBloc {}

class MockTaskDetailsBloc extends MockBloc<TaskDetailsEvent, TaskDetailsState>
    implements TaskDetailsBloc {}

class MockTaskFormBloc extends MockBloc<TaskFormEvent, TaskFormState>
    implements TaskFormBloc {}

class MockLocaleCubit extends MockCubit<Locale> implements LocaleCubit {}

class MockThemeCubit extends MockCubit<ThemeMode> implements AppThemeCubit {}
