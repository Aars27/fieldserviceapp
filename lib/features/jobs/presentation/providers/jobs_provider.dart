import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/job_local_datasource.dart';
import '../../data/datasources/job_remote_datasource.dart';
import '../../data/repositories/job_repository_impl.dart';
import '../../domain/entities/job.dart';
import '../../domain/entities/job_priority.dart';
import '../../domain/entities/job_status.dart';
import '../../domain/repositories/job_repository.dart';
import '../../domain/usecases/get_jobs_usecase.dart';
import '../../domain/usecases/update_job_status_usecase.dart';

// --------------- infrastructure ---------------

final jobLocalDatasourceProvider = Provider<JobLocalDatasource>((ref) {
  return JobLocalDatasource();
});

final jobRemoteDatasourceProvider = Provider<JobRemoteDatasource>((ref) {
  return JobRemoteDatasource(ref.read(dioProvider));
});

final jobRepositoryProvider = Provider<JobRepository>((ref) {
  return JobRepositoryImpl(
    ref.read(jobRemoteDatasourceProvider),
    ref.read(jobLocalDatasourceProvider),
  );
});

final getJobsUseCaseProvider = Provider<GetJobsUseCase>((ref) {
  return GetJobsUseCase(ref.read(jobRepositoryProvider));
});

final updateJobStatusUseCaseProvider = Provider<UpdateJobStatusUseCase>((ref) {
  return UpdateJobStatusUseCase(ref.read(jobRepositoryProvider));
});

// --------------- jobs list state ---------------

class JobsState {
  final List<Job> jobs;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final bool hasReachedEnd;
  final JobsFilter filter;
  final int currentPage;

  const JobsState({
    this.jobs = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.hasReachedEnd = false,
    this.filter = const JobsFilter(),
    this.currentPage = 1,
  });

  JobsState copyWith({
    List<Job>? jobs,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
    bool? hasReachedEnd,
    JobsFilter? filter,
    int? currentPage,
  }) {
    return JobsState(
      jobs: jobs ?? this.jobs,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      filter: filter ?? this.filter,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

final jobsNotifierProvider = NotifierProvider<JobsNotifier, JobsState>(JobsNotifier.new);

class JobsNotifier extends Notifier<JobsState> {
  final _debouncer = Debouncer(delay: AppConstants.searchDebounce);
  CancelToken? _activeCancelToken;

  @override
  JobsState build() {
    ref.onDispose(_debouncer.dispose);
    return const JobsState();
  }

  Future<void> loadInitial() => _fetch(page: 1, replace: true);

  Future<void> refresh() => _fetch(page: 1, replace: true);

  Future<void> loadMore() {
    if (state.isLoadingMore || state.hasReachedEnd) return Future.value();
    return _fetch(page: state.currentPage + 1, replace: false);
  }

  void search(String query) {
    final updated = state.filter.copyWith(search: query.isEmpty ? null : query);
    state = state.copyWith(filter: updated, clearError: true);
    _activeCancelToken?.cancel('new search');
    _activeCancelToken = CancelToken();
    _debouncer.run(() => _fetch(page: 1, replace: true, cancelToken: _activeCancelToken));
  }

  void applyFilter({
    Set<JobStatus>? statuses,
    Set<JobPriority>? priorities,
    DateTime? from,
    DateTime? to,
  }) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        statuses: statuses,
        priorities: priorities,
        from: from,
        to: to,
      ),
      clearError: true,
    );
    _fetch(page: 1, replace: true);
  }

  Future<void> _fetch({
    required int page,
    required bool replace,
    CancelToken? cancelToken,
  }) async {
    if (replace) {
      state = state.copyWith(isLoading: true, clearError: true, currentPage: 1);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    final result = await ref.read(getJobsUseCaseProvider).call(
          page: page,
          limit: AppConstants.jobsPageSize,
          filter: state.filter,
          cancelToken: cancelToken,
        );

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          errorMessage: failure.message,
        );
      },
      (jobs) {
        final merged = replace ? jobs : [...state.jobs, ...jobs];
        state = state.copyWith(
          jobs: merged,
          isLoading: false,
          isLoadingMore: false,
          hasReachedEnd: jobs.length < AppConstants.jobsPageSize,
          currentPage: page,
          clearError: true,
        );
      },
    );
  }
}
