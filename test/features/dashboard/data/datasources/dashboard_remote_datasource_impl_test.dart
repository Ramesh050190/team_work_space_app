import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:team_workspace/app/config/app_config.dart';
import 'package:team_workspace/core/constants/api_constants.dart';
import 'package:team_workspace/core/exceptions/network_exception.dart';
import 'package:team_workspace/core/exceptions/server_exception.dart';
import 'package:team_workspace/core/exceptions/timeout_exception.dart';
import 'package:team_workspace/features/dashboard/data/datasources/dashboard_remote_datasource_impl.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late DashboardRemoteDataSourceImpl dataSource;

  Map<String, dynamic> taskJson(int id) => {
        'id': id,
        'title': 'Task $id',
        'description': 'Desc',
        'status': 'pending',
        'priority': 'medium',
        'createdAt': '2026-07-20T08:00:00.000Z',
      };

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: AppConfig.development.apiBaseUrl));
    adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;
    dataSource = DashboardRemoteDataSourceImpl(dio: dio);
  });

  group('DashboardRemoteDataSourceImpl', () {
    test('parses data list and totalPages', () async {
      adapter.onGet(
        ApiConstants.tasksPath,
        (server) => server.reply(200, {
          'data': [taskJson(1)],
          'page': 1,
          'totalPages': 3,
        }),
        queryParameters: {'page': 1, 'limit': 10},
      );

      final result = await dataSource.getTasks(page: 1, limit: 10);
      expect(result.tasks, hasLength(1));
      expect(result.page, 1);
      expect(result.totalPages, 3);
    });

    test('uses items key and query params', () async {
      adapter.onGet(
        ApiConstants.tasksPath,
        (server) => server.reply(200, {
          'items': [taskJson(2), taskJson(3)],
          'page': 2,
          'total': 20,
        }),
        queryParameters: {
          'page': 2,
          'limit': 10,
          'q': 'flutter',
          'status': 'in_progress',
          'priority': 'high',
        },
      );

      final result = await dataSource.getTasks(
        page: 2,
        limit: 10,
        searchQuery: '  flutter  ',
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
      );

      expect(result.tasks, hasLength(2));
      expect(result.totalPages, 2);
    });

    test('throws ServerException on empty body', () async {
      adapter.onGet(
        ApiConstants.tasksPath,
        (server) => server.reply(200, null),
        queryParameters: {'page': 1, 'limit': 10},
      );

      expect(
        () => dataSource.getTasks(page: 1, limit: 10),
        throwsA(isA<ServerException>()),
      );
    });

    test('infers totalPages from hasMore false and short page', () async {
      adapter.onGet(
        ApiConstants.tasksPath,
        (server) => server.reply(200, {
          'data': [taskJson(1)],
          'page': 1,
          'hasMore': false,
        }),
        queryParameters: {'page': 1, 'limit': 10},
      );

      final result = await dataSource.getTasks(page: 1, limit: 10);
      expect(result.totalPages, 1);
    });

    test('infers totalPages from hasMore true', () async {
      adapter.onGet(
        ApiConstants.tasksPath,
        (server) => server.reply(200, {
          'data': List.generate(10, taskJson),
          'page': 1,
          'hasMore': true,
        }),
        queryParameters: {'page': 1, 'limit': 10},
      );

      final result = await dataSource.getTasks(page: 1, limit: 10);
      expect(result.totalPages, 2);
    });

    test('maps timeout DioException', () async {
      adapter.onGet(
        ApiConstants.tasksPath,
        (server) => server.throws(
          0,
          DioException(
            requestOptions: RequestOptions(path: ApiConstants.tasksPath),
            type: DioExceptionType.connectionTimeout,
          ),
        ),
        queryParameters: {'page': 1, 'limit': 10},
      );

      expect(
        () => dataSource.getTasks(page: 1, limit: 10),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('maps connectionError', () async {
      adapter.onGet(
        ApiConstants.tasksPath,
        (server) => server.throws(
          0,
          DioException(
            requestOptions: RequestOptions(path: ApiConstants.tasksPath),
            type: DioExceptionType.connectionError,
          ),
        ),
        queryParameters: {'page': 1, 'limit': 10},
      );

      expect(
        () => dataSource.getTasks(page: 1, limit: 10),
        throwsA(isA<NetworkException>()),
      );
    });

    test('maps HTTP error message', () async {
      adapter.onGet(
        ApiConstants.tasksPath,
        (server) => server.reply(500, {'message': 'Boom'}),
        queryParameters: {'page': 1, 'limit': 10},
      );

      expect(
        () => dataSource.getTasks(page: 1, limit: 10),
        throwsA(
          isA<ServerException>().having((e) => e.message, 'message', 'Boom'),
        ),
      );
    });
  });
}
