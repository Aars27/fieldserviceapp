import '../../../../core/errors/result.dart';
import '../../../jobs/domain/entities/job.dart';
import '../../../jobs/domain/entities/job_status.dart';
import '../../../jobs/domain/repositories/job_repository.dart';
import '../entities/dashboard_stats.dart';

class GetDashboardStatsUseCase {
  final JobRepository _repo;

  GetDashboardStatsUseCase(this._repo);

  Future<DashboardStats> call() async {
    final result = await _repo.getJobs(
      page: 1,
      limit: 100,
      filter: const JobsFilter(),
    );

    final List<Job> jobs;
    switch (result) {
      case Ok(:final value):
        jobs = value;
      case Err():
        final cachedResult = await _repo.getCachedJobs();
        jobs = switch (cachedResult) {
          Ok(:final value) => value,
          Err() => const [],
        };
    }

    final byStatus = <JobStatus, int>{};
    int overdueCount = 0;
    for (final job in jobs) {
      byStatus[job.status] = (byStatus[job.status] ?? 0) + 1;
      if (job.isOverdue) overdueCount++;
    }

    return DashboardStats(
      totalJobs: jobs.length,
      byStatus: byStatus,
      overdueCount: overdueCount,
    );
  }
}
