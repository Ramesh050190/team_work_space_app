import 'package:flutter_test/flutter_test.dart';
import 'package:team_workspace/features/dashboard/domain/entities/task_query.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';

void main() {
  group('TaskQuery', () {
    test('hasActiveFilters and hasSearch', () {
      const empty = TaskQuery();
      expect(empty.hasActiveFilters, isFalse);
      expect(empty.hasSearch, isFalse);

      const withSearch = TaskQuery(searchQuery: '  flutter ');
      expect(withSearch.hasSearch, isTrue);

      const withFilters = TaskQuery(
        status: TaskStatus.pending,
        priority: TaskPriority.high,
      );
      expect(withFilters.hasActiveFilters, isTrue);
    });

    test('copyWith updates and clear flags', () {
      const base = TaskQuery(
        searchQuery: 'q',
        status: TaskStatus.pending,
        priority: TaskPriority.low,
        page: 2,
        limit: 5,
      );

      final updated = base.copyWith(
        searchQuery: 'new',
        page: 3,
        clearStatus: true,
        clearPriority: true,
      );

      expect(updated.searchQuery, 'new');
      expect(updated.status, isNull);
      expect(updated.priority, isNull);
      expect(updated.page, 3);
      expect(updated.limit, 5);
    });

    test('clearFilters keeps search and resets page', () {
      const base = TaskQuery(
        searchQuery: 'keep',
        status: TaskStatus.completed,
        priority: TaskPriority.high,
        page: 4,
        limit: 15,
      );

      final cleared = base.clearFilters();
      expect(cleared.searchQuery, 'keep');
      expect(cleared.status, isNull);
      expect(cleared.priority, isNull);
      expect(cleared.page, 1);
      expect(cleared.limit, 15);
    });

    test('props equality', () {
      const a = TaskQuery(searchQuery: 'x', page: 1);
      const b = TaskQuery(searchQuery: 'x', page: 1);
      const c = TaskQuery(searchQuery: 'y', page: 1);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
