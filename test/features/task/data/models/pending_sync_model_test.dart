import 'package:flutter_test/flutter_test.dart';
import 'package:team_workspace/features/task/data/models/pending_sync_model.dart';
import 'package:team_workspace/features/task/data/models/task_model.dart';

void main() {
  test('PendingSyncModel serializes round-trip', () {
    final model = PendingSyncModel(
      operationId: 'op-1',
      taskId: -123,
      operationType: PendingOperationType.create,
      payload: const {'id': -123, 'title': 'Offline task'},
      createdAt: DateTime.parse('2026-07-23T10:00:00.000Z'),
      retryCount: 2,
    );

    final restored = PendingSyncModel.fromJson(model.toJson());

    expect(restored, equals(model));
  });

  test('PendingSyncModel normalizes Hive Map<dynamic, dynamic> payload', () {
    final raw = <dynamic, dynamic>{
      'operationId': 'op-2',
      'taskId': -42,
      'operationType': 'update',
      'payload': <dynamic, dynamic>{
        'id': -42,
        'title': 'Nested',
        'assignedUser': <dynamic, dynamic>{
          'id': 'u1',
          'name': 'Alex',
          'email': 'alex@example.com',
        },
      },
      'createdAt': '2026-07-23T10:00:00.000Z',
      'retryCount': 0,
    };

    final restored = PendingSyncModel.fromJson(Map<String, dynamic>.from(raw));

    expect(restored.payload['assignedUser'], isA<Map<String, dynamic>>());
    final task = TaskModel.fromJson({
      ...Map<String, dynamic>.from(restored.payload),
      'description': 'd',
      'priority': 'medium',
      'status': 'pending',
      'dueDate': '2026-07-25T00:00:00.000Z',
      'createdAt': '2026-07-20T08:00:00.000Z',
      'updatedAt': '2026-07-20T08:00:00.000Z',
      'completed': false,
    });
    expect(task.assignedUser.name, 'Alex');
  });

  test('TaskModel.fromJson accepts nested Map<dynamic, dynamic>', () {
    final json = <String, dynamic>{
      'id': 1,
      'title': 'Sample',
      'description': 'Desc',
      'priority': 'high',
      'status': 'pending',
      'dueDate': '2026-07-25T00:00:00.000Z',
      'assignedUser': <dynamic, dynamic>{
        'id': 'u1',
        'name': 'Alex',
        'email': 'alex@example.com',
        'avatarUrl': null,
      },
      'createdAt': '2026-07-20T08:00:00.000Z',
      'updatedAt': '2026-07-20T08:00:00.000Z',
      'completed': false,
    };

    final task = TaskModel.fromJson(json);

    expect(task.id, 1);
    expect(task.assignedUser.email, 'alex@example.com');
  });
}
