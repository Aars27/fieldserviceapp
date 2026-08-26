import 'package:equatable/equatable.dart';

import 'job_status.dart';

class StatusEvent extends Equatable {
  final String id;
  final JobStatus status;
  final String? note;
  final DateTime createdAt;

  const StatusEvent({
    required this.id,
    required this.status,
    this.note,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id];
}
