import 'package:flutter_test/flutter_test.dart';
import 'package:team_workspace/features/dashboard/data/models/task_model.dart';

void main() {
  group('dashboard TaskModel', () {
    test('fromJson handles int id and defaults', () {
      final model = TaskModel.fromJson({
        'id': 7,
        'createdAt': '2026-07-20T08:00:00.000Z',
      });

      expect(model.id, '7');
      expect(model.title, '');
      expect(model.description, '');
      expect(model.status, 'pending');
      expect(model.priority, 'medium');
    });

    test('fromJson parses DateTime / invalid / missing createdAt', () {
      final fromDt = TaskModel.fromJson({
        'id': '1',
        'title': 'T',
        'createdAt': DateTime.utc(2026, 1, 2),
      });
      expect(fromDt.createdAt, DateTime.utc(2026, 1, 2));

      final invalid = TaskModel.fromJson({'id': '1', 'createdAt': 'bad'});
      expect(invalid.createdAt, DateTime.fromMillisecondsSinceEpoch(0));

      final missing = TaskModel.fromJson({'id': '1'});
      expect(missing.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('toJson and toEntity round-trip', () {
      final model = TaskModel.fromJson({
        'id': '9',
        'title': 'Hello',
        'description': 'World',
        'status': 'completed',
        'priority': 'high',
        'createdAt': '2026-07-20T08:00:00.000Z',
      });

      expect(model.toJson()['title'], 'Hello');
      final entity = model.toEntity();
      expect(entity.id, '9');
      expect(entity.priority, 'high');
    });
  });
}
