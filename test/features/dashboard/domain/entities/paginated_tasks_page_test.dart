import 'package:flutter_test/flutter_test.dart';
import 'package:team_workspace/features/dashboard/domain/entities/paginated_tasks_page.dart';
import 'package:team_workspace/features/dashboard/domain/entities/task_entity.dart';

void main() {
  group('PaginatedTasksPage', () {
    final task = TaskEntity(
      id: '1',
      title: 'T',
      description: 'D',
      status: 'pending',
      createdAt: DateTime.utc(2026, 1, 1),
    );

    test('hasReachedMax when page >= totalPages', () {
      final page = PaginatedTasksPage(
        tasks: [task],
        page: 3,
        totalPages: 3,
      );
      expect(page.hasReachedMax, isTrue);
    });

    test('hasReachedMax when empty tasks and page > 1', () {
      const page = PaginatedTasksPage(tasks: [], page: 2, totalPages: 5);
      expect(page.hasReachedMax, isTrue);
    });

    test('hasReachedMax is false when more pages remain', () {
      final page = PaginatedTasksPage(
        tasks: [task],
        page: 1,
        totalPages: 4,
      );
      expect(page.hasReachedMax, isFalse);
    });

    test('props equality', () {
      final a = PaginatedTasksPage(tasks: [task], page: 1, totalPages: 2);
      final b = PaginatedTasksPage(tasks: [task], page: 1, totalPages: 2);
      expect(a, equals(b));
    });
  });
}
