import 'package:equatable/equatable.dart';

import '../../../jobs/domain/entities/job_status.dart';

class DashboardStats extends Equatable {
  final int totalJobs;
  final Map<JobStatus, int> byStatus;
  final int overdueCount;

  const DashboardStats({
    required this.totalJobs,
    required this.byStatus,
    required this.overdueCount,
  });

  int get inProgressCount => byStatus[JobStatus.inProgress] ?? 0;
  int get completedCount => byStatus[JobStatus.completed] ?? 0;
  int get pendingCount => byStatus[JobStatus.pending] ?? 0;

  @override
  List<Object?> get props => [totalJobs, overdueCount];
}
