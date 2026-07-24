import 'package:flutter_test/flutter_test.dart';
import 'package:team_workspace/features/task/data/models/task_model.dart';
import 'package:team_workspace/features/task/domain/entities/assigned_user.dart';
import 'package:team_workspace/features/task/domain/entities/task.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';

void main() {
  Map<String, dynamic> sampleJson({
    Object? id = 1,
    String? description,
    String? priority,
    String? status,
    Object? assignedUser,
    bool? completed,
  }) {
    return {
      'id': id,
      'title': 'Title',
      'description': description,
      'priority': priority,
      'status': status,
      'dueDate': '2026-07-25T00:00:00.000Z',
      'assignedUser':
          assignedUser ??
          {'id': 'u1', 'name': 'Alex', 'email': 'alex@example.com'},
      'createdAt': '2026-07-20T08:00:00.000Z',
      'updatedAt': '2026-07-20T08:00:00.000Z',
      if (completed != null) 'completed': completed,
    };
  }

  group('TaskModel', () {
    test('fromJson parses int and string ids with defaults', () {
      final fromInt = TaskModel.fromJson(sampleJson());
      expect(fromInt.id, 1);
      expect(fromInt.description, '');
      expect(fromInt.priority, TaskPriority.medium);
      expect(fromInt.status, TaskStatus.pending);
      expect(fromInt.completed, isFalse);

      final fromString = TaskModel.fromJson(
        sampleJson(
          id: '42',
          description: 'Desc',
          priority: 'high',
          status: 'in_progress',
          completed: true,
        ),
      );
      expect(fromString.id, 42);
      expect(fromString.priority, TaskPriority.high);
      expect(fromString.status, TaskStatus.inProgress);
      expect(fromString.completed, isTrue);

      final invalidId = TaskModel.fromJson(sampleJson(id: 'x'));
      expect(invalidId.id, 0);
    });

    test('fromJson normalizes Map<dynamic, dynamic> assignedUser', () {
      final model = TaskModel.fromJson(
        sampleJson(
          assignedUser: <dynamic, dynamic>{
            'id': 'u2',
            'name': 'Sam',
            'email': 'sam@example.com',
          },
        ),
      );
      expect(model.assignedUser.id, 'u2');
    });

    test('fromJson throws when assignedUser is not a map', () {
      expect(
        () => TaskModel.fromJson(sampleJson(assignedUser: 'bad')),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromEntity wraps plain AssignedUser', () {
      final entity = Task(
        id: 5,
        title: 'T',
        description: 'D',
        priority: TaskPriority.low,
        status: TaskStatus.completed,
        dueDate: DateTime.utc(2026, 8, 1),
        assignedUser: const AssignedUser(
          id: 'u9',
          name: 'Pat',
          email: 'pat@example.com',
        ),
        createdAt: DateTime.utc(2026, 7, 1),
        updatedAt: DateTime.utc(2026, 7, 2),
        completed: true,
      );

      final model = TaskModel.fromEntity(entity);
      expect(model.assignedUser, isA<AssignedUserModel>());
      expect(model.toCreateJson()['status'], 'completed');
      expect(model.toCreateJson().containsKey('id'), isFalse);
      expect(model.toJson()['status'], 'completed');
      expect(model.copyWith(title: 'New').title, 'New');
      expect(model.toEntity().id, 5);
    });

    test('fromEntity keeps AssignedUserModel and in_progress status', () {
      final model = TaskModel.fromEntity(
        TaskModel.fromJson(sampleJson(status: 'in_progress')),
      );
      expect(model.toJson()['status'], 'in_progress');
    });
  });

  group('AssignedUserModel', () {
    test('fromJson / toJson / copyWith', () {
      final model = AssignedUserModel.fromJson(const {
        'id': '1',
        'name': 'A',
        'email': 'a@b.com',
        'avatarUrl': 'http://x',
      });
      expect(model.toJson()['avatarUrl'], 'http://x');
      expect(model.copyWith(name: 'B').name, 'B');
      expect(model.toEntity().id, '1');
    });
  });
}
