import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../jobs/data/datasources/job_remote_datasource.dart';
import '../../../jobs/domain/entities/job.dart';
import '../../../jobs/presentation/providers/jobs_provider.dart';
import '../../notification_service.dart';

/// Manages the set of job IDs that have been seen/viewed by the user.
/// Persisted in SharedPreferences so it survives app restarts.
final seenJobsNotifierProvider =
    NotifierProvider<SeenJobsNotifier, Set<String>>(SeenJobsNotifier.new);

class SeenJobsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final isInitialized =
        prefs.getBool(AppConstants.seenJobsInitializedKey) ?? false;
    final savedList = prefs.getStringList(AppConstants.seenJobIdsKey);

    if (!isInitialized) {
      // First app launch / setup: mark all currently existing jobs as seen
      // so nothing is "new" retroactively.
      final initialJobIds = JobRemoteDatasource.getAllMockJobIds();
      final initialSet = initialJobIds.toSet();
      prefs.setStringList(AppConstants.seenJobIdsKey, initialSet.toList());
      prefs.setBool(AppConstants.seenJobsInitializedKey, true);
      return initialSet;
    }

    return (savedList ?? []).toSet();
  }

  /// Marks a specific job ID as seen and persists the updated set.
  Future<void> markSeen(String jobId) async {
    if (state.contains(jobId)) return;
    final updated = {...state, jobId};
    state = updated;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setStringList(AppConstants.seenJobIdsKey, updated.toList());
  }

  /// Marks multiple job IDs as seen and persists the updated set.
  Future<void> markAllSeen(Iterable<String> jobIds) async {
    final updated = {...state, ...jobIds};
    state = updated;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setStringList(AppConstants.seenJobIdsKey, updated.toList());
  }

  /// Clears seen status (used for testing or resetting).
  Future<void> reset() async {
    state = {};
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(AppConstants.seenJobIdsKey);
    await prefs.remove(AppConstants.seenJobsInitializedKey);
  }
}

/// Provides all known jobs across the in-memory mock DB, local cache, and current jobs state.
final allKnownJobsProvider = Provider<List<Job>>((ref) {
  final jobsState = ref.watch(jobsNotifierProvider);
  final local = ref
      .watch(jobLocalDatasourceProvider)
      .getAllJobs()
      .map((m) => m.toDomain())
      .toList();

  final Map<String, Job> map = {};
  for (final j in JobRemoteDatasource.getAllMockJobs().map((m) => m.toDomain())) {
    map[j.id] = j;
  }
  for (final j in local) {
    map[j.id] = j;
  }
  for (final j in jobsState.jobs) {
    map[j.id] = j;
  }
  return map.values.toList();
});

/// Returns all unseen/new jobs, sorted with most recent scheduled time first.
final unseenJobsProvider = Provider<List<Job>>((ref) {
  final seenIds = ref.watch(seenJobsNotifierProvider);
  final allJobs = ref.watch(allKnownJobsProvider);

  final unseen = allJobs.where((j) => !seenIds.contains(j.id)).toList();
  unseen.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
  return unseen;
});

/// Returns the count of unseen "new" jobs.
final unseenJobsCountProvider = Provider<int>((ref) {
  return ref.watch(unseenJobsProvider).length;
});

/// Debug / Review action: Simulates dispatching a new job from the backend.
/// 1. Inserts a new job at index 0 of the mock database.
/// 2. Fires an OS-level notification via NotificationService.
/// 3. Refreshes jobs and dashboard state so the UI and bell badge immediately reflect the new job.
Future<Job> simulateNewJobAction(WidgetRef ref) async {
  final newModel = JobRemoteDatasource.simulateNewJob();
  final newJob = newModel.toDomain();

  await NotificationService.showJobAssigned(newJob);

  ref.read(jobsNotifierProvider.notifier).refresh();
  ref.read(dashboardProvider.notifier).refresh();

  return newJob;
}
