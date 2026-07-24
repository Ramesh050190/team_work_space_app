import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:team_workspace/app/config/app_config.dart';
import 'package:team_workspace/core/constants/api_constants.dart';
import 'package:team_workspace/core/exceptions/network_exception.dart';
import 'package:team_workspace/core/exceptions/server_exception.dart';
import 'package:team_workspace/features/task/data/datasources/task_remote_datasource_impl.dart';
import 'package:team_workspace/features/task/data/models/task_model.dart';

void main() {
  late Dio dio;
  late DioAdapter dioAdapter;
  late TaskRemoteDataSourceImpl dataSource;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: AppConfig.development.apiBaseUrl));
    dioAdapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = dioAdapter;
    dataSource = TaskRemoteDataSourceImpl(dio: dio);
  });

  group('TaskRemoteDataSourceImpl', () {
    test('getTaskDetails returns TaskModel on success', () async {
      dioAdapter.onGet(
        ApiConstants.taskDetailsPath(1),
        (server) => server.reply(200, {
          'id': 1,
          'title': 'Test task',
          'description': 'Details',
          'priority': 'high',
          'status': 'pending',
          'dueDate': '2026-07-25T00:00:00.000Z',
          'assignedUser': {
            'id': 'u1',
            'name': 'Alex',
            'email': 'alex@example.com',
          },
          'createdAt': '2026-07-20T08:00:00.000Z',
          'updatedAt': '2026-07-20T08:00:00.000Z',
          'completed': false,
        }),
      );

      final result = await dataSource.getTaskDetails(1);

      expect(result.id, 1);
      expect(result.title, 'Test task');
      expect(result.completed, isFalse);
    });

    test('getTaskDetails throws ServerException on 500', () async {
      dioAdapter.onGet(
        ApiConstants.taskDetailsPath(1),
        (server) => server.reply(500, {'message': 'Internal error'}),
      );

      expect(
        () => dataSource.getTaskDetails(1),
        throwsA(isA<ServerException>()),
      );
    });

    test('updateTaskStatus returns updated TaskModel', () async {
      dioAdapter.onPatch(
        ApiConstants.updateTaskStatusPath(1),
        (server) => server.reply(200, {
          'id': 1,
          'title': 'Test task',
          'description': 'Details',
          'priority': 'high',
          'status': 'completed',
          'dueDate': '2026-07-25T00:00:00.000Z',
          'assignedUser': {
            'id': 'u1',
            'name': 'Alex',
            'email': 'alex@example.com',
          },
          'createdAt': '2026-07-20T08:00:00.000Z',
          'updatedAt': '2026-07-22T08:00:00.000Z',
          'completed': true,
        }),
        data: {'completed': true},
      );

      final result = await dataSource.updateTaskStatus(id: 1, completed: true);

      expect(result.completed, isTrue);
    });

    test(
      'updateTaskStatus throws NetworkException on connection error',
      () async {
        dioAdapter.onPatch(
          ApiConstants.updateTaskStatusPath(1),
          (server) => server.throws(
            0,
            DioException(
              requestOptions: RequestOptions(
                path: ApiConstants.updateTaskStatusPath(1),
              ),
              type: DioExceptionType.connectionError,
            ),
          ),
        );

        expect(
          () => dataSource.updateTaskStatus(id: 1, completed: true),
          throwsA(isA<NetworkException>()),
        );
      },
    );

    test('createTask returns TaskModel on success', () async {
      final task = TaskModel.fromJson(const {
        'id': 0,
        'title': 'Created task',
        'description': 'Created description',
        'priority': 'medium',
        'status': 'pending',
        'dueDate': '2026-07-28T00:00:00.000Z',
        'assignedUser': {
          'id': 'u1',
          'name': 'Alex',
          'email': 'alex@example.com',
          'avatarUrl': null,
        },
        'createdAt': '2026-07-23T08:00:00.000Z',
        'updatedAt': '2026-07-23T08:00:00.000Z',
        'completed': false,
      });

      dioAdapter.onPost(
        ApiConstants.tasksPath,
        (server) => server.reply(201, {
          ...task.toCreateJson(),
          'id': 10,
          'createdAt': '2026-07-23T08:00:00.000Z',
          'updatedAt': '2026-07-23T08:00:00.000Z',
        }),
        data: task.toCreateJson(),
      );

      final result = await dataSource.createTask(task);

      expect(result.id, 10);
      expect(result.title, 'Created task');
    });

    test('updateTask returns TaskModel on success', () async {
      final task = TaskModel.fromJson(const {
        'id': 1,
        'title': 'Updated task',
        'description': 'Updated description',
        'priority': 'low',
        'status': 'in_progress',
        'dueDate': '2026-07-28T00:00:00.000Z',
        'assignedUser': {
          'id': 'u1',
          'name': 'Alex',
          'email': 'alex@example.com',
          'avatarUrl': null,
        },
        'createdAt': '2026-07-20T08:00:00.000Z',
        'updatedAt': '2026-07-23T08:00:00.000Z',
        'completed': false,
      });

      dioAdapter.onPut(
        ApiConstants.taskDetailsPath(1),
        (server) => server.reply(200, task.toJson()),
        data: task.toJson(),
      );

      final result = await dataSource.updateTask(task);

      expect(result.title, 'Updated task');
      expect(result.priority.name, 'low');
    });
  });
}
