import 'package:equatable/equatable.dart';

/// Domain entity for a dashboard task (independent of data-layer models).
class TaskEntity extends Equatable {
  const TaskEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    this.priority = 'medium',
  });

  final String id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    status,
    priority,
    createdAt,
  ];
}
