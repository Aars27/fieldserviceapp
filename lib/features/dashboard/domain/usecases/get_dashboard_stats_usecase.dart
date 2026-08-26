import '../../../../core/errors/result.dart';
import '../../../jobs/domain/entities/job_status.dart';
import '../../../jobs/domain/repositories/job_repository.dart';
import '../entities/dashboard_stats.dart';

class GetDashboardStatsUseCase {
  final JobRepository _repo;

  GetDashboardStatsUseCase(this._repo);

  Future<DashboardStats> call() async {
    final result = await _repo.getCachedJobs();
    switch (result) {
      case Err():
        return const DashboardStats(totalJobs: 0, byStatus: {}, overdueCount: 0);
      case Ok(:final value):
        final byStatus = <JobStatus, int>{};
        int overdueCount = 0;
        for (final job in value) {
          byStatus[job.status] = (byStatus[job.status] ?? 0) + 1;
          if (job.isOverdue) overdueCount++;
        }
        return DashboardStats(
          totalJobs: value.length,
          byStatus: byStatus,
          overdueCount: overdueCount,
        );
    }
  }
}
