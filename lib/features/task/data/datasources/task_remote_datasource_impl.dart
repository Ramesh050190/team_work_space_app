import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:team_workspace/core/constants/api_constants.dart';
import 'package:team_workspace/core/exceptions/network_exception.dart';
import 'package:team_workspace/core/exceptions/server_exception.dart';
import 'package:team_workspace/core/exceptions/timeout_exception.dart';
import 'package:team_workspace/features/dashboard/domain/entities/task_query.dart';
import 'package:team_workspace/features/task/data/datasources/task_remote_datasource.dart';
import 'package:team_workspace/features/task/data/models/task_model.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  TaskRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<TaskModel> getTaskDetails(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.taskDetailsPath(id),
      );
      return TaskModel.fromJson(response.data!);
    } on DioException catch (error) {
      throw _mapDioException(error);
    } catch (_) {
      throw const ServerException(message: 'Failed to load task details');
    }
  }

  @override
  Future<TaskModel> updateTaskStatus({
    required int id,
    required bool completed,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiConstants.updateTaskStatusPath(id),
        data: {'completed': completed},
      );
      return TaskModel.fromJson(response.data!);
    } on DioException catch (error) {
      throw _mapDioException(error);
    } catch (_) {
      throw const ServerException(message: 'Failed to update task status');
    }
  }

  @override
  Future<TaskModel> createTask(TaskModel task) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.tasksPath,
        data: task.toCreateJson(),
      );
      return TaskModel.fromJson(response.data!);
    } on DioException catch (error) {
      throw _mapDioException(error);
    } catch (_) {
      throw const ServerException(message: 'Failed to create task');
    }
  }

  @override
  Future<TaskModel> updateTask(TaskModel task) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiConstants.taskDetailsPath(task.id),
        data: task.toJson(),
      );
      return TaskModel.fromJson(response.data!);
    } on DioException catch (error) {
      throw _mapDioException(error);
    } catch (_) {
      throw const ServerException(message: 'Failed to update task');
    }
  }

  @override
  Future<PaginatedTaskModels> queryTasks(TaskQuery query) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tasksPath,
        queryParameters: {
          'page': query.page,
          'limit': query.limit,
          if (query.searchQuery.trim().isNotEmpty)
            'q': query.searchQuery.trim(),
          if (query.status != null) 'status': _statusParam(query.status!),
          if (query.priority != null) 'priority': query.priority!.name,
        },
      );

      final data = response.data!;
      final rawList =
          (data['data'] ?? data['items']) as List<dynamic>? ??
          const <dynamic>[];
      final items = rawList
          .map((item) => TaskModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);

      final page = data['page'] as int? ?? query.page;
      final limit = data['limit'] as int? ?? query.limit;
      final totalPages = data['totalPages'] as int?;
      final total = data['total'] as int? ?? items.length;
      final hasMore =
          data['hasMore'] as bool? ??
          (totalPages != null ? page < totalPages : items.length >= limit);

      return PaginatedTaskModels(
        tasks: items,
        page: page,
        limit: limit,
        total: totalPages != null ? totalPages * limit : total,
        hasMore: hasMore,
      );
    } on DioException catch (error) {
      throw _mapDioException(error);
    } catch (_) {
      throw const ServerException(message: 'Failed to load tasks');
    }
  }

  String _statusParam(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'pending';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.completed:
        return 'completed';
    }
  }

  Exception _mapDioException(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const TimeoutException();
    }

    if (error.type == DioExceptionType.connectionError) {
      return const NetworkException();
    }

    final statusCode = error.response?.statusCode;
    final message =
        _extractMessage(error.response?.data) ??
        error.message ??
        'Unexpected server error';

    if (statusCode == null) {
      return NetworkException(message: message);
    }

    return ServerException(message: message, statusCode: statusCode);
  }

  String? _extractMessage(Object? data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String) return message;
    }

    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) {
          final message = decoded['message'];
          if (message is String) return message;
        }
      } catch (_) {
        return data;
      }
    }

    return null;
  }
}
