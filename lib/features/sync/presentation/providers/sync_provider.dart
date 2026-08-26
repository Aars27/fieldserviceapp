import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../jobs/presentation/providers/jobs_provider.dart';
import '../../data/sync_queue.dart';
import '../../data/sync_service.dart';

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

  @override
  SyncState build() {
    final connectivity = ref.read(connectivityServiceProvider);
    _connectivitySub = connectivity.onConnectivityChanged.listen((connected) {
      if (connected) _triggerSync();
    });
    ref.onDispose(() => _connectivitySub?.cancel());

    final queue = ref.read(syncQueueProvider);
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
