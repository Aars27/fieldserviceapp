import 'package:hive/hive.dart';

import '../../domain/entities/attachment.dart';
import '../../domain/entities/job.dart';
import '../../domain/entities/job_priority.dart';
import '../../domain/entities/job_status.dart';
import '../../domain/entities/status_event.dart';

part 'job_model.g.dart';

@HiveType(typeId: 1)
enum HiveJobStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  inProgress,
  @HiveField(2)
  completed,
  @HiveField(3)
  cancelled;

  JobStatus toDomain() => JobStatus.values[index];
  static HiveJobStatus fromDomain(JobStatus s) => HiveJobStatus.values[s.index];
}

@HiveType(typeId: 2)
enum HiveJobPriority {
  @HiveField(0)
  low,
  @HiveField(1)
  normal,
  @HiveField(2)
  high,
  @HiveField(3)
  urgent;

  JobPriority toDomain() => JobPriority.values[index];
  static HiveJobPriority fromDomain(JobPriority p) => HiveJobPriority.values[p.index];
}

@HiveType(typeId: 4)
class StatusEventModel extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  HiveJobStatus status;
  @HiveField(2)
  String? note;
  @HiveField(3)
  DateTime createdAt;

  StatusEventModel({
    required this.id,
    required this.status,
    this.note,
    required this.createdAt,
  });

  StatusEvent toDomain() => StatusEvent(
        id: id,
        status: status.toDomain(),
        note: note,
        createdAt: createdAt,
      );

  factory StatusEventModel.fromDomain(StatusEvent e) => StatusEventModel(
        id: e.id,
        status: HiveJobStatus.fromDomain(e.status),
        note: e.note,
        createdAt: e.createdAt,
      );

  factory StatusEventModel.fromJson(Map<String, dynamic> json) => StatusEventModel(
        id: json['id'] as String,
        status: HiveJobStatus.fromDomain(JobStatus.fromString(json['status'] as String)),
        note: json['note'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

@HiveType(typeId: 5)
class AttachmentModel extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String filename;
  @HiveField(2)
  String url;
  @HiveField(3)
  String mimeType;
  @HiveField(4)
  int sizeBytes;

  AttachmentModel({
    required this.id,
    required this.filename,
    required this.url,
    required this.mimeType,
    required this.sizeBytes,
  });

  Attachment toDomain() => Attachment(
        id: id,
        filename: filename,
        url: url,
        mimeType: mimeType,
        sizeBytes: sizeBytes,
      );

  factory AttachmentModel.fromDomain(Attachment a) => AttachmentModel(
        id: a.id,
        filename: a.filename,
        url: a.url,
        mimeType: a.mimeType,
        sizeBytes: a.sizeBytes,
      );

  factory AttachmentModel.fromJson(Map<String, dynamic> json) => AttachmentModel(
        id: json['id'] as String,
        filename: json['filename'] as String,
        url: json['url'] as String,
        mimeType: json['mime_type'] as String? ?? 'application/octet-stream',
        sizeBytes: (json['size_bytes'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'filename': filename,
        'url': url,
        'mime_type': mimeType,
        'size_bytes': sizeBytes,
      };
}

@HiveType(typeId: 0)
class JobModel extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String title;
  @HiveField(2)
  String description;
  @HiveField(3)
  HiveJobStatus status;
  @HiveField(4)
  HiveJobPriority priority;
  @HiveField(5)
  String assignedTo;
  @HiveField(6)
  DateTime scheduledAt;
  @HiveField(7)
  DateTime updatedAt;
  @HiveField(8)
  double? latitude;
  @HiveField(9)
  double? longitude;
  @HiveField(10)
  List<AttachmentModel> attachments;
  @HiveField(11)
  List<StatusEventModel> timeline;

  JobModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.assignedTo,
    required this.scheduledAt,
    required this.updatedAt,
    this.latitude,
    this.longitude,
    this.attachments = const [],
    this.timeline = const [],
  });

  Job toDomain() => Job(
        id: id,
        title: title,
        description: description,
        status: status.toDomain(),
        priority: priority.toDomain(),
        assignedTo: assignedTo,
        scheduledAt: scheduledAt,
        updatedAt: updatedAt,
        latitude: latitude,
        longitude: longitude,
        attachments: attachments.map((a) => a.toDomain()).toList(),
        timeline: timeline.map((e) => e.toDomain()).toList(),
      );

  factory JobModel.fromDomain(Job job) => JobModel(
        id: job.id,
        title: job.title,
        description: job.description,
        status: HiveJobStatus.fromDomain(job.status),
        priority: HiveJobPriority.fromDomain(job.priority),
        assignedTo: job.assignedTo,
        scheduledAt: job.scheduledAt,
        updatedAt: job.updatedAt,
        latitude: job.latitude,
        longitude: job.longitude,
        attachments: job.attachments.map(AttachmentModel.fromDomain).toList(),
        timeline: job.timeline.map(StatusEventModel.fromDomain).toList(),
      );

  factory JobModel.fromJson(Map<String, dynamic> json) => JobModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        status: HiveJobStatus.fromDomain(
          JobStatus.fromString(json['status'] as String),
        ),
        priority: HiveJobPriority.fromDomain(
          JobPriority.fromString(json['priority'] as String? ?? 'normal'),
        ),
        assignedTo: json['assigned_to'] as String? ?? '',
        scheduledAt: DateTime.parse(json['scheduled_at'] as String),
        updatedAt: DateTime.parse(
          json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
        ),
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        attachments: (json['attachments'] as List<dynamic>? ?? [])
            .map((e) => AttachmentModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        timeline: (json['timeline'] as List<dynamic>? ?? [])
            .map((e) => StatusEventModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
