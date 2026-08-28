import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/sync_queue.dart';

/// Singleton SyncQueue provider, imported by both jobs_provider and
/// sync_provider to avoid a circular import.
final syncQueueProvider = Provider<SyncQueue>((ref) => SyncQueue());
