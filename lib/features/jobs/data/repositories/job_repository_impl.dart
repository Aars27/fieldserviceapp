import 'dart:async';
import 'dart:convert';
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
import '../../../sync/data/sync_queue.dart';
import '../../../sync/domain/entities/pending_sync_operation.dart';

class JobRepositoryImpl implements JobRepository {
  final JobRemoteDatasource _remote;
  final JobLocalDatasource _local;
  final SyncQueue _syncQueue;

  JobRepositoryImpl(this._remote, this._local, this._syncQueue);

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

      // Preserve any locally-added attachments the mock "network" doesn't know about
      final cached = _local.getJob(id);
      if (cached != null && cached.attachments.isNotEmpty) {
        model.attachments = cached.attachments;
      }

      // Timeline events are appended inside the mock datasource (single source
      // of truth). No separate append here to avoid double-adding or reading
      // stale empty-timeline data from Hive.
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
      // Build a local attachment immediately so the UI can display it right away.
      // The real upload happens when SyncService drains this operation.
      final filename = file.path.split(Platform.pathSeparator).last;
      final bytes = await file.length();
      final attachmentId = 'att_${DateTime.now().millisecondsSinceEpoch}';

      final localModel = AttachmentModel(
        id: attachmentId,
        filename: filename,
        url: file.path,
        mimeType: 'image/jpeg',
        sizeBytes: bytes,
      );

      // Simulate upload progress bar completing (local save is instant).
      onProgress?.call(100, 100);

      // Persist the attachment in the local Hive cache so it survives restarts.
      final cached = _local.getJob(id);
      if (cached != null) {
        cached.attachments = [...cached.attachments, localModel];
        await _local.saveJob(cached);
      }

      // Enqueue a sync operation. SyncService will attempt the real upload
      // as soon as connectivity is available and remove the op on success,
      // at which point isAttachmentPendingSyncProvider returns false → "Synced".
      await _syncQueue.enqueue(PendingSyncOperation(
        id: attachmentId,
        type: SyncOperationType.addAttachment,
        jobId: id,
        payload: jsonEncode({
          'attachment_id': attachmentId,
          'filename': filename,
          'file_path': file.path,
        }),
        createdAt: DateTime.now(),
      ));

      return Ok(localModel.toDomain());
    } on ServerException catch (e) {
      return Err(ServerFailure(e.message));
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }

  Result<List<Job>> _fallbackToCache() {
    final cached = _local.getAllJobs();
    if (cached.isEmpty) return const Err(CacheFailure());
    return Ok(cached.map((m) => m.toDomain()).toList());
  }
}
