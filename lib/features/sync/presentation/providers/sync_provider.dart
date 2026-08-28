import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hive/hive.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../jobs/presentation/providers/jobs_provider.dart';
import '../../data/sync_queue.dart';
import '../../data/sync_service.dart';
import '../../domain/entities/pending_sync_operation.dart';

final syncQueueProvider = Provider<SyncQueue>((ref) => SyncQueue());

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref.read(jobRepositoryProvider), ref.read(syncQueueProvider));
});

class SyncState {
  final bool isSyncing;
  final int pendingCount;
  final int deadCount;

  const SyncState({
    this.isSyncing = false,
    this.pendingCount = 0,
    this.deadCount = 0,
  });

  SyncState copyWith({bool? isSyncing, int? pendingCount, int? deadCount}) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      deadCount: deadCount ?? this.deadCount,
    );
  }
}

final syncNotifierProvider = NotifierProvider<SyncNotifier, SyncState>(SyncNotifier.new);

class SyncNotifier extends Notifier<SyncState> {
  StreamSubscription<bool>? _connectivitySub;
  StreamSubscription<BoxEvent>? _boxSub;

  @override
  SyncState build() {
    final connectivity = ref.read(connectivityServiceProvider);
    _connectivitySub = connectivity.onConnectivityChanged.listen((connected) {
      if (connected) _triggerSync();
    });

    final queue = ref.read(syncQueueProvider);
    try {
      _boxSub = queue.watch().listen((_) {
        state = state.copyWith(
          pendingCount: queue.pendingCount,
          deadCount: queue.deadCount,
        );
      });
    } catch (_) {}

    ref.onDispose(() {
      _connectivitySub?.cancel();
      _boxSub?.cancel();
    });

    return SyncState(pendingCount: queue.pendingCount, deadCount: queue.deadCount);
  }

  Future<void> _triggerSync() async {
    if (state.isSyncing) return;
    final queue = ref.read(syncQueueProvider);
    if (queue.isEmpty) return;

    state = state.copyWith(isSyncing: true);
    await ref.read(syncServiceProvider).drainQueue();
    state = state.copyWith(
      isSyncing: false,
      pendingCount: queue.pendingCount,
      deadCount: queue.deadCount,
    );
  }
}

/// Provides the list of all currently pending sync operations.
final pendingSyncOperationsProvider = Provider<List<PendingSyncOperation>>((ref) {
  ref.watch(syncNotifierProvider);
  final queue = ref.read(syncQueueProvider);
  return queue.allPending;
});

/// Reactively checks whether a specific attachment on a given job is pending sync.
final isAttachmentPendingSyncProvider =
    Provider.family<bool, ({String jobId, String attachmentId, String? filename})>(
        (ref, params) {
  // Watching syncNotifierProvider ensures this recomputes whenever queue changes or drains
  ref.watch(syncNotifierProvider);
  final queue = ref.read(syncQueueProvider);
  return queue.allPending.any((op) {
    if (op.type != SyncOperationType.addAttachment) return false;
    if (op.jobId != params.jobId) return false;
    if (op.id == params.attachmentId) return true;
    if (op.payload.contains(params.attachmentId)) return true;
    if (params.filename != null && op.payload.contains(params.filename!)) {
      return true;
    }
    return false;
  });
});

/// Reactively checks whether a specific job has ANY pending sync operations in the queue.
final isJobPendingSyncProvider = Provider.family<bool, String>((ref, jobId) {
  // Watching syncNotifierProvider ensures this recomputes whenever queue changes or drains
  ref.watch(syncNotifierProvider);
  final queue = ref.read(syncQueueProvider);
  return queue.allPending.any((op) => op.jobId == jobId);
});
