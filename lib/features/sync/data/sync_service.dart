import 'dart:convert';
import 'dart:io';

import 'package:fieldserviceapp/core/errors/result.dart';

import '../../jobs/data/datasources/job_remote_datasource.dart';
import '../../jobs/domain/entities/job_status.dart';
import '../../jobs/domain/repositories/job_repository.dart';
import '../domain/entities/pending_sync_operation.dart';
import 'sync_queue.dart';

const _maxRetries = 3;

class SyncService {
  final JobRepository _jobRepo;
  final SyncQueue _queue;
  final JobRemoteDatasource _remote;

  SyncService(this._jobRepo, this._queue, this._remote);

  Future<int> drainQueue() async {
    int synced = 0;
    while (!_queue.isEmpty) {
      final op = _queue.peekFirst();
      if (op == null) break;

      final success = await _execute(op);
      if (success) {
        await _queue.dequeueFirst();
        synced++;
      } else {
        if (op.retryCount >= _maxRetries - 1) {
          // Exhausted retries — move to dead-letter along with any later
          // ops for the same job to preserve operation order.
          await _queue.moveToDead(op);
        } else {
          await _queue.incrementRetry(op);
        }
        // Stop draining on failure — retry next connectivity event.
        break;
      }
    }
    return synced;
  }

  Future<bool> _execute(PendingSyncOperation op) async {
    try {
      switch (op.type) {
        case SyncOperationType.updateStatus:
          final payload = jsonDecode(op.payload) as Map<String, dynamic>;
          final newStatus = JobStatus.fromString(payload['status'] as String);
          // Last-write-wins: if there are two status updates for the same job
          // in the queue, the later one will overwrite the earlier. This is
          // acceptable for our use case but not suitable for collaborative editing.
          final result = await _jobRepo.updateJobStatus(op.jobId, newStatus);
          return switch (result) {
            Ok() => true,
            Err() => false,
          };

        case SyncOperationType.addAttachment:
          // Parse the file path that was persisted when the op was enqueued.
          final payload = jsonDecode(op.payload) as Map<String, dynamic>;
          final filePath = payload['file_path'] as String?;
          if (filePath == null) return false;

          final file = File(filePath);
          if (!file.existsSync()) {
            // File was deleted from cache — nothing to upload, mark done.
            return true;
          }

          try {
            // Attempt the real upload to the remote (mock or real API).
            await _remote.uploadAttachment(op.jobId, file);
            return true;
          } catch (_) {
            return false;
          }
      }
    } catch (_) {
      return false;
    }
  }
}
