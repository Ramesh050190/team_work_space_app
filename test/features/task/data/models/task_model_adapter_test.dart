import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:team_workspace/features/task/data/models/task_model.dart';
import 'package:team_workspace/features/task/data/models/task_model_adapter.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('task_adapter_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TaskModelAdapter());
    }
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('TaskModelAdapter round-trips via Hive', () async {
    final box = await Hive.openBox<TaskModel>('adapter_box');
    final model = TaskModel.fromJson(const {
      'id': 11,
      'title': 'Adapter',
      'description': 'Round trip',
      'priority': 'high',
      'status': 'in_progress',
      'dueDate': '2026-07-25T00:00:00.000Z',
      'assignedUser': {'id': 'u1', 'name': 'Alex', 'email': 'alex@example.com'},
      'createdAt': '2026-07-20T08:00:00.000Z',
      'updatedAt': '2026-07-21T08:00:00.000Z',
      'completed': false,
    });

    await box.put('k', model);
    final restored = box.get('k');

    expect(restored?.id, 11);
    expect(restored?.title, 'Adapter');
    expect(restored?.assignedUser.name, 'Alex');
    expect(restored?.status.name, 'inProgress');
  });
}
