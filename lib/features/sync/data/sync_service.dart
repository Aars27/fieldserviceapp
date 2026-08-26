import 'dart:convert';

import 'package:fieldserviceapp/core/errors/result.dart';

import '../../jobs/domain/entities/job_status.dart';
import '../../jobs/domain/repositories/job_repository.dart';
import '../domain/entities/pending_sync_operation.dart';
import 'sync_queue.dart';

const _maxRetries = 3;

class SyncService {
  final JobRepository _jobRepo;
  final SyncQueue _queue;

  SyncService(this._jobRepo, this._queue);

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
          // Attachment re-upload on sync is not yet implemented — attachments
          // should be queued as file paths but we'd need to re-open the file.
          // TODO: implement attachment sync when the file path is persisted in the op.
          return false;
      }
    } catch (_) {
      return false;
    }
  }
}
