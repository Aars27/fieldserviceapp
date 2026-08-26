import 'package:equatable/equatable.dart';

import 'attachment.dart';
import 'job_priority.dart';
import 'job_status.dart';
import 'status_event.dart';

class Job extends Equatable {
  final String id;
  final String title;
  final String description;
  final JobStatus status;
  final JobPriority priority;
  final String assignedTo;
  final DateTime scheduledAt;
  final DateTime updatedAt;
  final double? latitude;
  final double? longitude;
  final List<Attachment> attachments;
  final List<StatusEvent> timeline;

  const Job({
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

  bool get isOverdue =>
      scheduledAt.isBefore(DateTime.now()) &&
      status != JobStatus.completed &&
      status != JobStatus.cancelled;

  Job copyWith({
    JobStatus? status,
    List<Attachment>? attachments,
    List<StatusEvent>? timeline,
  }) {
    return Job(
      id: id,
      title: title,
      description: description,
      status: status ?? this.status,
      priority: priority,
      assignedTo: assignedTo,
      scheduledAt: scheduledAt,
      updatedAt: updatedAt,
      latitude: latitude,
      longitude: longitude,
      attachments: attachments ?? this.attachments,
      timeline: timeline ?? this.timeline,
    );
  }

  @override
  List<Object?> get props => [id, status, updatedAt];
}
