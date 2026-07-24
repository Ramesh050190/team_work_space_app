import 'package:hive/hive.dart';
import 'package:team_workspace/features/task/data/models/task_model.dart';

/// Manual Hive adapter for [TaskModel] (JSON map under the hood).
class TaskModelAdapter extends TypeAdapter<TaskModel> {
  @override
  final int typeId = 1;

  @override
  TaskModel read(BinaryReader reader) {
    final map = Map<String, dynamic>.from(reader.readMap());
    // Nested maps from Hive need a deep cast for assignedUser.
    final assigned = Map<String, dynamic>.from(map['assignedUser'] as Map);
    return TaskModel.fromJson({
      ...map,
      'assignedUser': assigned,
      'dueDate': map['dueDate'] is DateTime
          ? (map['dueDate'] as DateTime).toIso8601String()
          : map['dueDate'],
      'createdAt': map['createdAt'] is DateTime
          ? (map['createdAt'] as DateTime).toIso8601String()
          : map['createdAt'],
      'updatedAt': map['updatedAt'] is DateTime
          ? (map['updatedAt'] as DateTime).toIso8601String()
          : map['updatedAt'],
    });
  }

  @override
  void write(BinaryWriter writer, TaskModel obj) {
    writer.writeMap(obj.toJson());
  }
}
