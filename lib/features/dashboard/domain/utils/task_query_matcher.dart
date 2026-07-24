import 'package:team_workspace/features/dashboard/domain/entities/task_query.dart';
import 'package:team_workspace/features/task/domain/entities/task.dart';

/// Pure filtering helpers used by local cache and unit tests.
class TaskQueryMatcher {
  TaskQueryMatcher._();

  static List<Task> apply(List<Task> source, TaskQuery query) {
    final normalized = query.searchQuery.trim().toLowerCase();

    return source
        .where((task) {
          final matchesSearch =
              normalized.isEmpty ||
              task.title.toLowerCase().contains(normalized);
          final matchesStatus =
              query.status == null || task.status == query.status;
          final matchesPriority =
              query.priority == null || task.priority == query.priority;
          return matchesSearch && matchesStatus && matchesPriority;
        })
        .toList(growable: false);
  }

  static List<Task> paginate(
    List<Task> source, {
    required int page,
    required int limit,
  }) {
    if (page < 1 || limit < 1) return const [];
    final start = (page - 1) * limit;
    if (start >= source.length) return const [];
    final end = (start + limit).clamp(0, source.length);
    return source.sublist(start, end);
  }
}
