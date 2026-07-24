import 'package:flutter_test/flutter_test.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';

void main() {
  group('TaskStatus', () {
    test('fromString aliases and default', () {
      expect(TaskStatus.fromString('pending'), TaskStatus.pending);
      expect(TaskStatus.fromString('IN_PROGRESS'), TaskStatus.inProgress);
      expect(TaskStatus.fromString('inprogress'), TaskStatus.inProgress);
      expect(TaskStatus.fromString('completed'), TaskStatus.completed);
      expect(TaskStatus.fromString('unknown'), TaskStatus.pending);
    });

    test('label for each value', () {
      expect(TaskStatus.pending.label, 'Pending');
      expect(TaskStatus.inProgress.label, 'In Progress');
      expect(TaskStatus.completed.label, 'Completed');
    });
  });

  group('TaskPriority', () {
    test('fromString and default', () {
      expect(TaskPriority.fromString('low'), TaskPriority.low);
      expect(TaskPriority.fromString('MEDIUM'), TaskPriority.medium);
      expect(TaskPriority.fromString('high'), TaskPriority.high);
      expect(TaskPriority.fromString('???'), TaskPriority.medium);
    });

    test('label for each value', () {
      expect(TaskPriority.low.label, 'Low');
      expect(TaskPriority.medium.label, 'Medium');
      expect(TaskPriority.high.label, 'High');
    });
  });
}
