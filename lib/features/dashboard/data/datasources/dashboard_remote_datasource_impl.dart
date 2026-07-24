import 'package:dio/dio.dart';
import 'package:team_workspace/core/constants/api_constants.dart';
import 'package:team_workspace/core/exceptions/network_exception.dart';
import 'package:team_workspace/core/exceptions/server_exception.dart';
import 'package:team_workspace/core/exceptions/timeout_exception.dart';
import 'package:team_workspace/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:team_workspace/features/dashboard/data/models/task_model.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';

/// Dio implementation of [DashboardRemoteDataSource].
class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  DashboardRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<DashboardTasksResponse> getTasks({
    required int page,
    required int limit,
    String searchQuery = '',
    TaskStatus? status,
    TaskPriority? priority,
  }) async {
    try {
      final trimmedQuery = searchQuery.trim();
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tasksPath,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (trimmedQuery.isNotEmpty) 'q': trimmedQuery,
          if (status != null) 'status': _statusParam(status),
          if (priority != null) 'priority': priority.name,
        },
      );

      final body = response.data;
      if (body == null) {
        throw const ServerException(message: 'Empty response from server');
      }

      final rawList =
          (body['data'] ?? body['items']) as List<dynamic>? ??
          const <dynamic>[];

      final tasks = rawList
          .map(
            (item) =>
                TaskModel.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(growable: false);

      final currentPage = body['page'] as int? ?? page;
      final totalPages =
          body['totalPages'] as int? ??
          _inferTotalPages(
            page: currentPage,
            limit: limit,
            itemCount: tasks.length,
            total: body['total'] as int?,
            hasMore: body['hasMore'] as bool?,
          );

      return DashboardTasksResponse(
        tasks: tasks,
        page: currentPage,
        totalPages: totalPages,
      );
    } on DioException catch (error) {
      throw _mapDioException(error);
    } on ServerException {
      rethrow;
    } catch (_) {
      throw const ServerException(message: 'Failed to load tasks');
    }
  }

  String _statusParam(TaskStatus status) {
    return status == TaskStatus.inProgress ? 'in_progress' : status.name;
  }

  int _inferTotalPages({
    required int page,
    required int limit,
    required int itemCount,
    int? total,
    bool? hasMore,
  }) {
    if (total != null && limit > 0) {
      return (total / limit).ceil().clamp(1, 1 << 30);
    }
    if (hasMore == false) return page;
    if (hasMore == true) return page + 1;
    if (itemCount < limit) return page;
    return page + 1;
  }

  Exception _mapDioException(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const TimeoutException();
    }
    if (error.type == DioExceptionType.connectionError) {
      return const NetworkException(message: 'No internet connection');
    }
    final statusCode = error.response?.statusCode;
    final message = error.response?.data is Map
        ? Map<String, dynamic>.from(error.response!.data as Map)['message']
                  as String? ??
              error.message
        : error.message;
    return ServerException(
      message: message ?? 'Server error',
      statusCode: statusCode,
    );
  }
}
