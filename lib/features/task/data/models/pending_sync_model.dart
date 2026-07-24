import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

/// Supported offline mutation types queued for later sync.
enum PendingOperationType { create, update, statusChange, delete }

/// Hive-backed outbox entry for offline-first synchronization.
class PendingSyncModel extends Equatable {
  const PendingSyncModel({
    required this.operationId,
    required this.taskId,
    required this.operationType,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
  });

  final String operationId;
  final int taskId;
  final PendingOperationType operationType;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;

  factory PendingSyncModel.fromJson(Map<String, dynamic> json) {
    return PendingSyncModel(
      operationId: json['operationId'] as String,
      taskId: json['taskId'] as int,
      operationType: PendingOperationType.values.firstWhere(
        (value) => value.name == json['operationType'],
        orElse: () => PendingOperationType.update,
      ),
      // Hive may restore nested maps as Map<dynamic, dynamic>.
      payload: _normalizePayload(json['payload']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }

  static Map<String, dynamic> _normalizePayload(dynamic value) {
    if (value is! Map) {
      return <String, dynamic>{};
    }
    return value.map((key, val) {
      final normalizedKey = key.toString();
      if (val is Map) {
        return MapEntry(normalizedKey, _normalizePayload(val));
      }
      if (val is List) {
        return MapEntry(
          normalizedKey,
          val
              .map((item) => item is Map ? _normalizePayload(item) : item)
              .toList(),
        );
      }
      return MapEntry(normalizedKey, val);
    });
  }

  Map<String, dynamic> toJson() {
    return {
      'operationId': operationId,
      'taskId': taskId,
      'operationType': operationType.name,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
    };
  }

  PendingSyncModel copyWith({
    String? operationId,
    int? taskId,
    PendingOperationType? operationType,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    int? retryCount,
  }) {
    return PendingSyncModel(
      operationId: operationId ?? this.operationId,
      taskId: taskId ?? this.taskId,
      operationType: operationType ?? this.operationType,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  @override
  List<Object?> get props => [
    operationId,
    taskId,
    operationType,
    payload,
    createdAt,
    retryCount,
  ];
}

class PendingSyncModelAdapter extends TypeAdapter<PendingSyncModel> {
  @override
  final int typeId = 2;

  @override
  PendingSyncModel read(BinaryReader reader) {
    final map = Map<String, dynamic>.from(reader.readMap());
    return PendingSyncModel.fromJson(map);
  }

  @override
  void write(BinaryWriter writer, PendingSyncModel obj) {
    writer.writeMap(obj.toJson());
  }
}
