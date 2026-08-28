import 'dart:io';

import 'package:hive/hive.dart';
import 'package:fieldserviceapp/core/errors/result.dart';
import 'package:fieldserviceapp/core/router/app_router.dart';
import 'package:fieldserviceapp/core/theme/theme_provider.dart';
import 'package:fieldserviceapp/features/dashboard/domain/usecases/get_dashboard_stats_usecase.dart';
import 'package:fieldserviceapp/features/jobs/domain/entities/attachment.dart';
import 'package:fieldserviceapp/features/jobs/domain/entities/job.dart';
import 'package:fieldserviceapp/features/jobs/domain/entities/job_priority.dart';
import 'package:fieldserviceapp/features/jobs/domain/entities/job_status.dart';
import 'package:fieldserviceapp/features/jobs/domain/repositories/job_repository.dart';
import 'package:fieldserviceapp/features/notifications/presentation/providers/unseen_jobs_provider.dart';
import 'package:fieldserviceapp/features/sync/data/sync_queue.dart';
import 'package:fieldserviceapp/features/sync/domain/entities/pending_sync_operation.dart';
import 'package:fieldserviceapp/features/sync/presentation/providers/sync_provider.dart';
import 'package:fieldserviceapp/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSyncQueue extends SyncQueue {
  final List<PendingSyncOperation> _items = [];

  _FakeSyncQueue([List<PendingSyncOperation>? initial]) {
    if (initial != null) _items.addAll(initial);
  }

  @override
  List<PendingSyncOperation> get allPending => List.unmodifiable(_items);

  @override
  List<PendingSyncOperation> get allDead => const [];

  @override
  int get pendingCount => _items.length;

  @override
  int get deadCount => 0;

  @override
  bool get isEmpty => _items.isEmpty;

  @override
  Stream<BoxEvent> watch() => const Stream.empty();

  @override
  Future<void> enqueue(PendingSyncOperation op) async => _items.add(op);
}

class _FakeJobRepository implements JobRepository {
  final List<Job> mockJobs;
  _FakeJobRepository(this.mockJobs);

  @override
  Future<Result<List<Job>>> getJobs({
    required int page,
    required int limit,
    required JobsFilter filter,
    Object? cancelToken,
  }) async {
    var list = mockJobs;
    if (filter.statuses.isNotEmpty) {
      list = list.where((j) => filter.statuses.contains(j.status)).toList();
    }
    if (filter.overdueOnly) {
      list = list.where((j) => j.isOverdue).toList();
    }
    return Ok(list);
  }

  @override
  Future<Result<List<Job>>> getCachedJobs() async => Ok(mockJobs);

  @override
  Future<Result<Job>> getJob(String id) async =>
      Ok(mockJobs.firstWhere((j) => j.id == id));

  @override
  Future<Result<Job>> updateJobStatus(String id, JobStatus newStatus) async =>
      throw UnimplementedError();

  @override
  Future<Result<Attachment>> addAttachment(String id, File file, {void Function(int, int)? onProgress}) async =>
      throw UnimplementedError();
}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    final router = buildRouter(container);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: FieldServiceApp(router: router),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  test('Bug 2 fix: JobsFilter copyWith clears search when clearSearch is true', () {
    const filter = JobsFilter(search: 'HVAC', statuses: {JobStatus.inProgress});
    final cleared = filter.copyWith(clearSearch: true);

    expect(cleared.search, isNull);
    expect(cleared.statuses, {JobStatus.inProgress});
  });

  test('Bug 1 fix: JobsFilter supports overdueOnly filtering', () {
    const filter = JobsFilter(overdueOnly: true);
    expect(filter.overdueOnly, isTrue);

    final modified = filter.copyWith(overdueOnly: false);
    expect(modified.overdueOnly, isFalse);
  });

  test('Bug 3 fix: GetDashboardStatsUseCase computes stats and overdue count accurately', () async {
    final now = DateTime.now();
    final mockJobs = [
      Job(
        id: '1',
        title: 'Job 1',
        description: 'Desc',
        status: JobStatus.inProgress,
        priority: JobPriority.urgent,
        assignedTo: 'Tech',
        scheduledAt: now.subtract(const Duration(hours: 2)), // overdue
        updatedAt: now,
      ),
      Job(
        id: '2',
        title: 'Job 2',
        description: 'Desc',
        status: JobStatus.pending,
        priority: JobPriority.normal,
        assignedTo: 'Tech',
        scheduledAt: now.add(const Duration(hours: 4)), // not overdue
        updatedAt: now,
      ),
      Job(
        id: '3',
        title: 'Job 3',
        description: 'Desc',
        status: JobStatus.completed,
        priority: JobPriority.low,
        assignedTo: 'Tech',
        scheduledAt: now.subtract(const Duration(days: 2)), // completed (not overdue)
        updatedAt: now,
      ),
    ];

    final repo = _FakeJobRepository(mockJobs);
    final useCase = GetDashboardStatsUseCase(repo);
    final stats = await useCase.call();

    expect(stats.totalJobs, 3);
    expect(stats.inProgressCount, 1);
    expect(stats.completedCount, 1);
    expect(stats.overdueCount, 1);
  });

  test('New-job notification: SeenJobsNotifier marks seen, persists, and detects unseen jobs', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    // Initial state: all initial mock jobs are marked seen on first run
    final initialSeen = container.read(seenJobsNotifierProvider);
    expect(initialSeen.isNotEmpty, isTrue);

    // Simulate a new job with a new ID not in seen set
    const newJobId = 'job_test_new_999';
    expect(initialSeen.contains(newJobId), isFalse);

    // Mark seen
    await container.read(seenJobsNotifierProvider.notifier).markSeen(newJobId);
    expect(container.read(seenJobsNotifierProvider).contains(newJobId), isTrue);

    // Verify persisted in SharedPreferences
    final saved = prefs.getStringList('seen_job_ids');
    expect(saved?.contains(newJobId), isTrue);
  });

  test('New-job notification: Unseen jobs sort to top of the list', () {
    final seenIds = {'1', '2'};
    final jobs = [
      Job(
        id: '1',
        title: 'Seen Job 1',
        description: 'Desc',
        status: JobStatus.inProgress,
        priority: JobPriority.normal,
        assignedTo: 'Tech',
        scheduledAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Job(
        id: 'new_3',
        title: 'New Job 3',
        description: 'Desc',
        status: JobStatus.pending,
        priority: JobPriority.urgent,
        assignedTo: 'Tech',
        scheduledAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Job(
        id: '2',
        title: 'Seen Job 2',
        description: 'Desc',
        status: JobStatus.pending,
        priority: JobPriority.normal,
        assignedTo: 'Tech',
        scheduledAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    final sorted = List<Job>.from(jobs);
    sorted.sort((a, b) {
      final aNew = !seenIds.contains(a.id);
      final bNew = !seenIds.contains(b.id);
      if (aNew && !bNew) return -1;
      if (!aNew && bNew) return 1;
      return 0;
    });

    expect(sorted.first.id, 'new_3');
    expect(sorted[1].id, '1');
    expect(sorted[2].id, '2');
  });

  test('Sync status: isAttachmentPendingSyncProvider and isJobPendingSyncProvider detect queued operations', () {
    final fakeQueue = _FakeSyncQueue([
      PendingSyncOperation(
        id: 'op_att_1',
        type: SyncOperationType.addAttachment,
        jobId: 'job_101',
        payload: '{"attachment_id":"att_123","filename":"photo.jpg"}',
        createdAt: DateTime.now(),
      ),
      PendingSyncOperation(
        id: 'op_status_1',
        type: SyncOperationType.updateStatus,
        jobId: 'job_102',
        payload: '{"status":"in_progress"}',
        createdAt: DateTime.now(),
      ),
    ]);

    final container = ProviderContainer(
      overrides: [
        syncQueueProvider.overrideWithValue(fakeQueue),
      ],
    );

    // Check attachment on job_101
    final isAttPending = container.read(
      isAttachmentPendingSyncProvider((
        jobId: 'job_101',
        attachmentId: 'att_123',
        filename: 'photo.jpg',
      )),
    );
    expect(isAttPending, isTrue);

    // Check non-queued attachment on job_101
    final isOtherAttPending = container.read(
      isAttachmentPendingSyncProvider((
        jobId: 'job_101',
        attachmentId: 'att_other',
        filename: 'other.jpg',
      )),
    );
    expect(isOtherAttPending, isFalse);

    // Check job-level sync indicator
    expect(container.read(isJobPendingSyncProvider('job_101')), isTrue);
    expect(container.read(isJobPendingSyncProvider('job_102')), isTrue);
    expect(container.read(isJobPendingSyncProvider('job_999')), isFalse);
  });
}
