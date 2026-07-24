import 'package:dio/dio.dart';
import 'package:team_workspace/features/dashboard/domain/entities/task_query.dart';
import 'package:team_workspace/features/dashboard/domain/utils/task_query_matcher.dart';
import 'package:team_workspace/features/task/data/models/task_model.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';

/// mock responses for app works without a live backend.
/// Enabled per flavor via [AppConfig.useTaskMock].
class MockTaskInterceptor extends Interceptor {
  MockTaskInterceptor({Map<int, TaskModel>? seedTasks})
    : _tasks = Map<int, TaskModel>.from(seedTasks ?? _defaultSeedTasks) {
    active = this;
  }

  /// Last constructed interceptor (used to reset mock data on account switch).
  static MockTaskInterceptor? active;

  final Map<int, TaskModel> _tasks;

  /// Restores the default list.
  void reset() {
    _tasks
      ..clear()
      ..addAll(_defaultSeedTasks);
  }

  static Map<int, TaskModel> get _defaultSeedTasks {
    const priorities = TaskPriority.values;
    const statuses = TaskStatus.values;
    final titles = <String>[
      'Design dashboard wireframes',
      'Write API documentation',
      'Ship release build',
      'Plan sprint meeting',
      'Review pull requests',
      'Update onboarding screens',
      'Fix login timeout bug',
      'Prepare quarterly report',
      'Refactor task repository',
      'Add analytics events',
      'Improve search performance',
      'Create marketing banners',
      'Audit accessibility labels',
      'Migrate legacy filters',
      'Draft support playbook',
      'Optimize image caching',
      'Sync calendar reminders',
      'Validate payment flow',
      'Polish empty states',
      'Investigate crash reports',
      'Document release checklist',
      'Triage customer feedback',
      'Build notification center',
      'Test offline fallbacks',
      'Align design tokens',
    ];

    final map = <int, TaskModel>{};
    for (var i = 0; i < titles.length; i++) {
      final id = i + 1;
      final priority = priorities[i % priorities.length];
      final status = statuses[i % statuses.length];
      final completed = status == TaskStatus.completed;
      map[id] = TaskModel.fromJson({
        'id': id,
        'title': titles[i],
        'description':
            'Detailed notes for "${titles[i]}" covering scope, owners, and acceptance criteria.',
        'priority': priority.name,
        'status': status == TaskStatus.inProgress ? 'in_progress' : status.name,
        'dueDate': DateTime.utc(2026, 7, 24 + (i % 20)).toIso8601String(),
        'assignedUser': {
          'id': 'u${(i % 3) + 1}',
          'name': ['Alex Morgan', 'Jamie Lee', 'Taylor Kim'][i % 3],
          'email': [
            'alex@example.com',
            'jamie@example.com',
            'taylor@example.com',
          ][i % 3],
          'avatarUrl': null,
        },
        'createdAt': DateTime.utc(2026, 7, 1 + (i % 15)).toIso8601String(),
        'updatedAt': DateTime.utc(2026, 7, 10 + (i % 10)).toIso8601String(),
        'completed': completed,
      });
    }
    return map;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    /// Dio may pass "/tasks"
    /// full URL path, or "tasks".
    final path = _normalizePath(options.path);
    final getMatch = RegExp(r'^/tasks/(-?\d+)$').firstMatch(path);
    final patchMatch = RegExp(r'^/tasks/(-?\d+)/status$').firstMatch(path);

    /// GET /taskslist with search/filter/pagination
    if (options.method == 'GET' && path == '/tasks') {
      final params = options.queryParameters;
      final page = int.tryParse('${params['page'] ?? 1}') ?? 1;
      final limit = int.tryParse('${params['limit'] ?? 10}') ?? 10;
      final q = '${params['q'] ?? ''}';
      final statusParam = params['status'] as String?;
      final priorityParam = params['priority'] as String?;

      final query = TaskQuery(
        searchQuery: q,
        status: statusParam == null ? null : TaskStatus.fromString(statusParam),
        priority: priorityParam == null
            ? null
            : TaskPriority.fromString(priorityParam),
        page: page,
        limit: limit,
      );

      final all = _tasks.values.map((model) => model.toEntity()).toList();
      final filtered = TaskQueryMatcher.apply(all, query);
      final pageItems = TaskQueryMatcher.paginate(
        filtered,
        page: page,
        limit: limit,
      );
      final hasMore = page * limit < filtered.length;
      final totalPages = limit <= 0
          ? 1
          : ((filtered.length + limit - 1) ~/ limit).clamp(1, 1 << 30);

      final jsonItems = pageItems
          .map((task) => TaskModel.fromEntity(task).toJson())
          .toList();

      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'data': jsonItems,
            'items': jsonItems,
            'page': page,
            'limit': limit,
            'total': filtered.length,
            'totalPages': totalPages,
            'hasMore': hasMore,
          },
        ),
      );
      return;
    }

    /// POST /tasks for create
    if (options.method == 'POST' && path == '/tasks') {
      final data = Map<String, dynamic>.from(options.data as Map);
      if (data['assignedUser'] is Map) {
        data['assignedUser'] = Map<String, dynamic>.from(
          data['assignedUser'] as Map,
        );
      }
      final nextId =
          (_tasks.keys.isEmpty
              ? 0
              : _tasks.keys.reduce((a, b) => a > b ? a : b)) +
          1;
      final now = DateTime.now().toUtc();
      final created = TaskModel.fromJson({
        ...data,
        'id': nextId,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'dueDate':
            data['dueDate'] ??
            now.add(const Duration(days: 7)).toIso8601String(),
        'assignedUser':
            data['assignedUser'] ??
            {
              'id': 'u1',
              'name': 'Alex Morgan',
              'email': 'alex@example.com',
              'avatarUrl': null,
            },
        'completed': data['completed'] ?? false,
        'status': data['status'] ?? 'pending',
        'priority': data['priority'] ?? 'medium',
        'description': data['description'] ?? '',
        'title': data['title'] ?? 'Untitled',
      });
      _tasks[nextId] = created;
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 201,
          data: created.toJson(),
        ),
      );
      return;
    }

    /// PUT /tasks/:id  for update (upsert if missing so remapped sync ids still work)
    if (options.method == 'PUT' && getMatch != null) {
      final id = int.parse(getMatch.group(1)!);
      final data = Map<String, dynamic>.from(options.data as Map);
      final existing = _tasks[id];
      final updated = TaskModel.fromJson({
        ...?existing?.toJson(),
        ...data,
        'id': id,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        if (existing == null && data['assignedUser'] == null)
          'assignedUser': {
            'id': 'u1',
            'name': 'Alex Morgan',
            'email': 'alex@example.com',
            'avatarUrl': null,
          },
        if (existing == null && data['createdAt'] == null)
          'createdAt': DateTime.now().toUtc().toIso8601String(),
      });
      _tasks[id] = updated;
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: updated.toJson(),
        ),
      );
      return;
    }

    if (options.method == 'GET' && getMatch != null) {
      final id = int.parse(getMatch.group(1)!);
      final task = _tasks[id];
      if (task == null) {
        handler.reject(_notFound(options));
        return;
      }

      handler.resolve(
        Response(requestOptions: options, statusCode: 200, data: task.toJson()),
      );
      return;
    }

    if (options.method == 'PATCH' && patchMatch != null) {
      final id = int.parse(patchMatch.group(1)!);
      final task = _tasks[id];
      if (task == null) {
        handler.reject(_notFound(options));
        return;
      }

      final completed = options.data['completed'] as bool? ?? false;
      final updated = task.copyWith(
        completed: completed,
        status: completed ? TaskStatus.completed : TaskStatus.pending,
        updatedAt: DateTime.now().toUtc(),
      );
      _tasks[id] = updated;

      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: updated.toJson(),
        ),
      );
      return;
    }

    handler.next(options);
  }

  /// for /api/v1 prefixes so path matching is stable.
  String _normalizePath(String rawPath) {
    var path = rawPath.trim();
    if (path.startsWith('http://') || path.startsWith('https://')) {
      path = Uri.parse(path).path;
    }
    /// baseUrl ends with /api/v1 — strip that from the path.
    const prefixes = ['/api/v1', '/api'];
    for (final prefix in prefixes) {
      if (path.startsWith(prefix)) {
        path = path.substring(prefix.length);
        break;
      }
    }
    if (!path.startsWith('/')) {
      path = '/$path';
    }
    /// Drop trailing slash except for root.
    if (path.length > 1 && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    return path;
  }

  DioException _notFound(RequestOptions options) {
    return DioException(
      requestOptions: options,
      response: Response(
        requestOptions: options,
        statusCode: 404,
        data: {'message': 'Task not found'},
      ),
      type: DioExceptionType.badResponse,
    );
  }

  static List<TaskModel> get seedTasks =>
      _defaultSeedTasks.values.toList(growable: false);
}
