import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:team_workspace/app/config/app_config.dart';
import 'package:team_workspace/core/constants/api_constants.dart';
import 'package:team_workspace/core/exceptions/network_exception.dart';
import 'package:team_workspace/core/exceptions/server_exception.dart';
import 'package:team_workspace/core/exceptions/timeout_exception.dart';
import 'package:team_workspace/features/dashboard/data/datasources/dashboard_remote_datasource_impl.dart';

void main() {
  late Dio dio;
  late DioAdapter dioAdapter;
  late DashboardRemoteDataSourceImpl dataSource;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: AppConfig.development.apiBaseUrl));
    dioAdapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = dioAdapter;
    dataSource = DashboardRemoteDataSourceImpl(dio: dio);
  });

  group('DashboardRemoteDataSourceImpl', () {
    test('getTasks returns tasks from data key', () async {
      dioAdapter.onGet(
        ApiConstants.tasksPath,
        (server) => server.reply(200, {
          'data': [
            {
              'id': '1',
              'title': 'Dashboard task',
              'description': 'Details',
              'status': 'pending',
              'priority': 'high',
              'createdAt': '2026-07-20T08:00:00.000Z',
            },
          ],
          'page': 1,
          'totalPages': 3,
        }),
        queryParameters: {'page': 1, 'limit': 10},
      );

      final result = await dataSource.getTasks(page: 1, limit: 10);

      expect(result.tasks, hasLength(1));
      expect(result.tasks.single.id, '1');
      expect(result.tasks.single.title, 'Dashboard task');
      expect(result.page, 1);
      expect(result.totalPages, 3);
    });

    test('getTasks throws ServerException when body is null', () async {
      dioAdapter.onGet(
        ApiConstants.tasksPath,
        (server) => server.reply(200, null),
        queryParameters: {'page': 1, 'limit': 10},
      );

      expect(
        () => dataSource.getTasks(page: 1, limit: 10),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            'Empty response from server',
          ),
        ),
      );
    });

    test('getTasks throws TimeoutException on connectionTimeout', () async {
      dioAdapter.onGet(
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

    test('getTasks throws NetworkException on connectionError', () async {
      dioAdapter.onGet(
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
  });
}
