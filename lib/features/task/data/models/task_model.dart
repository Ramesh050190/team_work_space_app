import 'package:team_workspace/features/task/domain/entities/assigned_user.dart';
import 'package:team_workspace/features/task/domain/entities/task.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';

class AssignedUserModel extends AssignedUser {
  const AssignedUserModel({
    required super.id,
    required super.name,
    required super.email,
    super.avatarUrl,
  });

  factory AssignedUserModel.fromJson(Map<String, dynamic> json) {
    return AssignedUserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email, 'avatarUrl': avatarUrl};
  }

  AssignedUser toEntity() => this;

  AssignedUserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
  }) {
    return AssignedUserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

class TaskModel extends Task {
  const TaskModel({
    required super.id,
    required super.title,
    required super.description,
    required super.priority,
    required super.status,
    required super.dueDate,
    required super.assignedUser,
    required super.createdAt,
    required super.updatedAt,
    required super.completed,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: _parseId(json['id']),
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      priority: TaskPriority.fromString(
        json['priority'] as String? ?? 'medium',
      ),
      status: TaskStatus.fromString(json['status'] as String? ?? 'pending'),
      dueDate: DateTime.parse(json['dueDate'] as String),
      // Hive restores nested maps as Map<dynamic, dynamic>; normalize first.
      assignedUser: AssignedUserModel.fromJson(
        _asStringKeyedMap(json['assignedUser']),
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      completed: json['completed'] as bool? ?? false,
    );
  }

  static int _parseId(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }

  /// Hive / Dio can yield [Map<dynamic, dynamic>]; cast safely for nested JSON.
  static Map<String, dynamic> _asStringKeyedMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    throw FormatException(
      'Expected assignedUser map, got ${value.runtimeType}',
    );
  }

  /// Builds a [TaskModel] from a domain [Task] for create/update API calls.
  factory TaskModel.fromEntity(Task task) {
    return TaskModel(
      id: task.id,
      title: task.title,
      description: task.description,
      priority: task.priority,
      status: task.status,
      dueDate: task.dueDate,
      assignedUser: task.assignedUser is AssignedUserModel
          ? task.assignedUser as AssignedUserModel
          : AssignedUserModel(
              id: task.assignedUser.id,
              name: task.assignedUser.name,
              email: task.assignedUser.email,
              avatarUrl: task.assignedUser.avatarUrl,
            ),
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
      completed: task.completed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.name,
      'status': _statusToJson(status),
      'dueDate': dueDate.toIso8601String(),
      'assignedUser': _assignedUserModel.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'completed': completed,
    };
  }

  /// Payload for create — server assigns id / timestamps.
  Map<String, dynamic> toCreateJson() {
    return {
      'title': title,
      'description': description,
      'priority': priority.name,
      'status': _statusToJson(status),
      'dueDate': dueDate.toIso8601String(),
      'assignedUser': _assignedUserModel.toJson(),
      'completed': completed,
    };
  }

  AssignedUserModel get _assignedUserModel {
    if (assignedUser is AssignedUserModel) {
      return assignedUser as AssignedUserModel;
    }
    return AssignedUserModel(
      id: assignedUser.id,
      name: assignedUser.name,
      email: assignedUser.email,
      avatarUrl: assignedUser.avatarUrl,
    );
  }

  Task toEntity() => this;

  @override
  TaskModel copyWith({
    int? id,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    AssignedUser? assignedUser,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? completed,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      assignedUser: assignedUser ?? this.assignedUser,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completed: completed ?? this.completed,
    );
  }

  static String _statusToJson(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'pending';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.completed:
        return 'completed';
    }
  }
}
