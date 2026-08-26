import 'package:hive/hive.dart';

part 'pending_sync_operation.g.dart';

@HiveType(typeId: 6)
enum SyncOperationType {
  @HiveField(0)
  updateStatus,
  @HiveField(1)
  addAttachment,
}

@HiveType(typeId: 3)
class PendingSyncOperation extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  SyncOperationType type;

  @HiveField(2)
  String jobId;

  /// JSON-encoded payload, e.g. '{"status":"in_progress"}' for a status update.
  @HiveField(3)
  String payload;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  int retryCount;

  PendingSyncOperation({
    required this.id,
    required this.type,
    required this.jobId,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
  });
}
