import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:team_workspace/core/constants/api_constants.dart';
import 'package:team_workspace/core/errors/failure.dart';
import 'package:team_workspace/core/usecases/usecase.dart';
import 'package:team_workspace/features/dashboard/domain/entities/paginated_tasks_page.dart';
import 'package:team_workspace/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';

/// Loads a paginated list of tasks for the dashboard (cache + remote).
class GetTasksUseCase implements UseCase<PaginatedTasksPage, GetTasksParams> {
  GetTasksUseCase(this._repository);

  final DashboardRepository _repository;

  @override
  Future<Either<Failure, PaginatedTasksPage>> call(GetTasksParams params) {
    return _repository.getTasks(
      page: params.page,
      limit: params.limit,
      cacheOnly: params.cacheOnly,
      searchQuery: params.searchQuery,
      status: params.status,
      priority: params.priority,
    );
  }
}

class GetTasksParams extends Equatable {
  const GetTasksParams({
    this.page = 1,
    this.limit = ApiConstants.defaultPageSize,
    this.cacheOnly = false,
    this.searchQuery = '',
    this.status,
    this.priority,
  });

  final int page;
  final int limit;
  final bool cacheOnly;
  final String searchQuery;
  final TaskStatus? status;
  final TaskPriority? priority;

  @override
  List<Object?> get props => [
    page,
    limit,
    cacheOnly,
    searchQuery,
    status,
    priority,
  ];
}
