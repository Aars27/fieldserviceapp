import 'dart:io';

import 'package:fieldserviceapp/core/errors/result.dart';
import 'package:fieldserviceapp/core/router/app_router.dart';
import 'package:fieldserviceapp/core/theme/theme_provider.dart';
import 'package:fieldserviceapp/features/dashboard/domain/usecases/get_dashboard_stats_usecase.dart';
import 'package:fieldserviceapp/features/jobs/domain/entities/attachment.dart';
import 'package:fieldserviceapp/features/jobs/domain/entities/job.dart';
import 'package:fieldserviceapp/features/jobs/domain/entities/job_priority.dart';
import 'package:fieldserviceapp/features/jobs/domain/entities/job_status.dart';
import 'package:fieldserviceapp/features/jobs/domain/repositories/job_repository.dart';
import 'package:fieldserviceapp/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}
