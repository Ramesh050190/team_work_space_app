import 'package:equatable/equatable.dart';
import 'package:team_workspace/features/task/domain/entities/assigned_user.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';

/// Core business object representing a task in the domain layer.
class Task extends Equatable {
  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.dueDate,
    required this.assignedUser,
    required this.createdAt,
    required this.updatedAt,
    required this.completed,
  });

  final int id;
  final String title;
  final String description;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime dueDate;
  final AssignedUser assignedUser;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool completed;

  Task copyWith({
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
    return Task(
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

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    priority,
    status,
    dueDate,
    assignedUser,
    createdAt,
    updatedAt,
    completed,
  ];
}
