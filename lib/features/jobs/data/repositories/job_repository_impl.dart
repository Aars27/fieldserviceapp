import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/attachment.dart';
import '../../domain/entities/job.dart';
import '../../domain/entities/job_status.dart';
import '../../domain/repositories/job_repository.dart';
import '../datasources/job_local_datasource.dart';
import '../datasources/job_remote_datasource.dart';
import '../models/job_model.dart';
import '../../../notifications/notification_service.dart';

class JobRepositoryImpl implements JobRepository {
  final JobRemoteDatasource _remote;
  final JobLocalDatasource _local;

  JobRepositoryImpl(this._remote, this._local);

  @override
  Future<Result<List<Job>>> getJobs({
    required int page,
    required int limit,
    required JobsFilter filter,
    Object? cancelToken,
  }) async {
    try {
      final models = await _remote.getJobs(
        page: page,
        limit: limit,
        filter: filter,
        cancelToken: cancelToken is CancelToken ? cancelToken : null,
      );
      if (page == 1) {
        // Only replace cache on fresh loads, not paginated appends
        final isDefaultFilter = filter.search == null &&
            filter.statuses.isEmpty &&
            filter.priorities.isEmpty &&
            filter.from == null &&
            filter.to == null &&
            !filter.overdueOnly;
        await _local.saveJobs(models, clear: isDefaultFilter);
      } else {
        for (final m in models) {
          await _local.saveJob(m);
        }
      }
      final jobs = models.map((m) => m.toDomain()).toList();
      // Schedule deadline reminders for all fetched jobs.
      for (final job in jobs) {
        unawaited(NotificationService.scheduleDeadlineReminder(job));
      }
      return Ok(jobs);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        // Caller cancelled deliberately — return the current cache silently
        return Ok(_local.getAllJobs().map((m) => m.toDomain()).toList());
      }
      return _fallbackToCache();
    } on ServerException catch (e) {
      return Err(ServerFailure(e.message));
    }
  }

  @override
  Future<Result<List<Job>>> getCachedJobs() async {
    final cached = _local.getAllJobs();
    return Ok(cached.map((m) => m.toDomain()).toList());
  }

  @override
  Future<Result<Job>> getJob(String id) async {
    try {
      final model = await _remote.getJob(id);
      await _local.saveJob(model);
      final job = model.toDomain();
      unawaited(NotificationService.scheduleDeadlineReminder(job));
      return Ok(job);
    } on ServerException catch (e) {
      try {
        final cached = _local.getJob(id);
        return Ok(cached!.toDomain());
      } on CacheException {
        return Err(ServerFailure(e.message));
      }
    }
  }

  @override
  Future<Result<Job>> updateJobStatus(String id, JobStatus newStatus) async {
    try {
      final model = await _remote.updateJobStatus(id, newStatus);
      
      final cached = _local.getJob(id);
      if (cached != null) {
        // Preserve local attachments that the remote mock might have lost
        model.attachments = cached.attachments;
        
        // Append the new timeline event and sort most recent first
        final newEvent = StatusEventModel(
          id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
          status: HiveJobStatus.fromDomain(newStatus),
          createdAt: DateTime.now(),
          note: 'Status updated',
        );
        model.timeline = List.from(cached.timeline)..add(newEvent);
        model.timeline.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      await _local.saveJob(model);
      // Cancel deadline reminder when job reaches a terminal state.
      if (newStatus == JobStatus.completed || newStatus == JobStatus.cancelled) {
        unawaited(NotificationService.cancelDeadlineReminder(id));
      }
      return Ok(model.toDomain());
    } on ServerException catch (e) {
      return Err(ServerFailure(e.message));
    }
  }

  @override
  Future<Result<Attachment>> addAttachment(
    String id,
    File file, {
    void Function(int, int)? onProgress,
  }) async {
    try {
      final model = await _remote.uploadAttachment(id, file, onProgress: onProgress);
      // Update the cached job with the new attachment
      final cached = _local.getJob(id);
      if (cached != null) {
        cached.attachments = [...cached.attachments, model];
        await _local.saveJob(cached);
      }
      return Ok(model.toDomain());
    } on ServerException catch (e) {
      return Err(ServerFailure(e.message));
    }
  }

  Result<List<Job>> _fallbackToCache() {
    final cached = _local.getAllJobs();
    if (cached.isEmpty) return const Err(CacheFailure());
    return Ok(cached.map((m) => m.toDomain()).toList());
  }
}
