import 'dart:io';

import '../../../../core/errors/result.dart';
import '../entities/attachment.dart';
import '../entities/job.dart';
import '../entities/job_priority.dart';
import '../entities/job_status.dart';

class JobsFilter {
  final String? search;
  final Set<JobStatus> statuses;
  final Set<JobPriority> priorities;
  final DateTime? from;
  final DateTime? to;
  final bool overdueOnly;

  const JobsFilter({
    this.search,
    this.statuses = const {},
    this.priorities = const {},
    this.from,
    this.to,
    this.overdueOnly = false,
  });

  JobsFilter copyWith({
    String? search,
    bool clearSearch = false,
    Set<JobStatus>? statuses,
    Set<JobPriority>? priorities,
    DateTime? from,
    bool clearFrom = false,
    DateTime? to,
    bool clearTo = false,
    bool? overdueOnly,
  }) {
    return JobsFilter(
      search: clearSearch ? null : (search ?? this.search),
      statuses: statuses ?? this.statuses,
      priorities: priorities ?? this.priorities,
      from: clearFrom ? null : (from ?? this.from),
      to: clearTo ? null : (to ?? this.to),
      overdueOnly: overdueOnly ?? this.overdueOnly,
    );
  }
}

abstract class JobRepository {
  Future<Result<List<Job>>> getJobs({
    required int page,
    required int limit,
    required JobsFilter filter,
    Object? cancelToken,
  });

  Future<Result<List<Job>>> getCachedJobs();

  Future<Result<Job>> getJob(String id);

  Future<Result<Job>> updateJobStatus(String id, JobStatus newStatus);

  Future<Result<Attachment>> addAttachment(
    String id,
    File file, {
    void Function(int, int)? onProgress,
  });
}
