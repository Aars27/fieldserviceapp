import 'package:hive/hive.dart';

import '../../../../core/constants/app_constants.dart';
import '../domain/entities/pending_sync_operation.dart';

const _deadLetterBoxName = 'dead_letter_box';

class SyncQueue {
  Box<PendingSyncOperation> get _box =>
      Hive.box<PendingSyncOperation>(AppConstants.pendingSyncBoxName);

  Box<PendingSyncOperation> get _deadBox =>
      Hive.box<PendingSyncOperation>(_deadLetterBoxName);

  Future<void> enqueue(PendingSyncOperation op) => _box.put(op.id, op);

  PendingSyncOperation? peekFirst() {
    if (_box.isEmpty) return null;
    // Hive boxes maintain insertion order for string keys when iterated.
    // We use createdAt to find the earliest entry regardless.
    return _box.values.reduce(
      (a, b) => a.createdAt.isBefore(b.createdAt) ? a : b,
    );
  }

  Future<void> dequeueFirst() async {
    final first = peekFirst();
    if (first != null) await first.delete();
  }

  /// Increments retryCount in-place. The op stays at its original position
  /// in the queue — we never reorder by moving it to the end.
  Future<void> incrementRetry(PendingSyncOperation op) async {
    op.retryCount++;
    await op.save();
  }

  /// Removes from the live queue and writes to the dead-letter box.
  /// Also moves any later ops for the same job to dead-letter to preserve order.
  Future<void> moveToDead(PendingSyncOperation op) async {
    final sameJobOps = _box.values
        .where((o) => o.jobId == op.jobId && o.id != op.id)
        .toList();

    await op.delete();
    await _deadBox.put(op.id, op);

    for (final sibling in sameJobOps) {
      await sibling.delete();
      await _deadBox.put(sibling.id, sibling);
    }
  }

  bool get _isBoxOpen => Hive.isBoxOpen(AppConstants.pendingSyncBoxName);
  bool get _isDeadBoxOpen => Hive.isBoxOpen(_deadLetterBoxName);

  Box<PendingSyncOperation>? get _maybeBox =>
      _isBoxOpen ? Hive.box<PendingSyncOperation>(AppConstants.pendingSyncBoxName) : null;

  Box<PendingSyncOperation>? get _maybeDeadBox =>
      _isDeadBoxOpen ? Hive.box<PendingSyncOperation>(_deadLetterBoxName) : null;

  bool get isEmpty => _maybeBox?.isEmpty ?? true;

  int get pendingCount => _maybeBox?.length ?? 0;

  int get deadCount => _maybeDeadBox?.length ?? 0;

  List<PendingSyncOperation> get allPending => _maybeBox?.values.toList() ?? [];

  List<PendingSyncOperation> get allDead => _maybeDeadBox?.values.toList() ?? [];

  Stream<BoxEvent> watch() => _maybeBox?.watch() ?? const Stream.empty();

  static String get deadLetterBoxName => _deadLetterBoxName;
}
