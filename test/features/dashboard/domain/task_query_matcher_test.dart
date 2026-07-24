import 'package:flutter_test/flutter_test.dart';
import 'package:team_workspace/features/dashboard/domain/entities/task_query.dart';
import 'package:team_workspace/features/dashboard/domain/utils/task_query_matcher.dart';
import 'package:team_workspace/features/task/domain/entities/assigned_user.dart';
import 'package:team_workspace/features/task/domain/entities/task.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';

void main() {
  final tasks = [
    Task(
      id: 1,
      title: 'Plan sprint meeting',
      description: 'Agenda',
      priority: TaskPriority.high,
      status: TaskStatus.pending,
      dueDate: DateTime.parse('2026-07-28T00:00:00.000Z'),
      assignedUser: const AssignedUser(
        id: 'u1',
        name: 'Alex',
        email: 'alex@example.com',
      ),
      createdAt: DateTime.parse('2026-07-20T08:00:00.000Z'),
      updatedAt: DateTime.parse('2026-07-20T08:00:00.000Z'),
      completed: false,
    ),
    Task(
      id: 2,
      title: 'Write API documentation',
      description: 'Docs',
      priority: TaskPriority.medium,
      status: TaskStatus.inProgress,
      dueDate: DateTime.parse('2026-07-29T00:00:00.000Z'),
      assignedUser: const AssignedUser(
        id: 'u2',
        name: 'Jamie',
        email: 'jamie@example.com',
      ),
      createdAt: DateTime.parse('2026-07-20T08:00:00.000Z'),
      updatedAt: DateTime.parse('2026-07-20T08:00:00.000Z'),
      completed: false,
    ),
    Task(
      id: 3,
      title: 'Team meeting notes',
      description: 'Notes',
      priority: TaskPriority.high,
      status: TaskStatus.pending,
      dueDate: DateTime.parse('2026-07-30T00:00:00.000Z'),
      assignedUser: const AssignedUser(
        id: 'u1',
        name: 'Alex',
        email: 'alex@example.com',
      ),
      createdAt: DateTime.parse('2026-07-20T08:00:00.000Z'),
      updatedAt: DateTime.parse('2026-07-20T08:00:00.000Z'),
      completed: false,
    ),
  ];

  group('TaskQueryMatcher', () {
    test('search is case-insensitive and trims whitespace', () {
      final result = TaskQueryMatcher.apply(
        tasks,
        const TaskQuery(searchQuery: '  MEETING  '),
      );

      expect(result.map((task) => task.id), [1, 3]);
    });

    test('filters by status and priority', () {
      final result = TaskQueryMatcher.apply(
        tasks,
        const TaskQuery(
          status: TaskStatus.pending,
          priority: TaskPriority.high,
        ),
      );

      expect(result.map((task) => task.id), [1, 3]);
    });

    test('combines search with status and priority', () {
      final result = TaskQueryMatcher.apply(
        tasks,
        const TaskQuery(
          searchQuery: 'meeting',
          status: TaskStatus.pending,
          priority: TaskPriority.high,
        ),
      );

      expect(result.map((task) => task.id), [1, 3]);
    });

    test('paginate returns the requested page without overflow', () {
      final page = TaskQueryMatcher.paginate(tasks, page: 2, limit: 2);
      expect(page.map((task) => task.id), [3]);
    });
  });
}
