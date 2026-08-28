import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/repositories/job_repository.dart';
import '../providers/jobs_provider.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/job_card.dart';

class JobsListScreen extends ConsumerStatefulWidget {
  final JobsFilter? initialFilter;

  const JobsListScreen({super.key, this.initialFilter});

  @override
  ConsumerState<JobsListScreen> createState() => _JobsListScreenState();
}

class _JobsListScreenState extends ConsumerState<JobsListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() {
      if (widget.initialFilter != null) {
        ref.read(jobsNotifierProvider.notifier).setFilter(widget.initialFilter!);
      } else {
        ref.read(jobsNotifierProvider.notifier).loadInitial();
      }
    });
  }

  @override
  void didUpdateWidget(JobsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFilter != oldWidget.initialFilter && widget.initialFilter != null) {
      Future.microtask(() {
        ref.read(jobsNotifierProvider.notifier).setFilter(widget.initialFilter!);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(jobsNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobsNotifierProvider);
    final activeFilterCount = state.filter.statuses.length +
        state.filter.priorities.length +
        (state.filter.from != null ? 1 : 0) +
        (state.filter.to != null ? 1 : 0) +
        (state.filter.overdueOnly ? 1 : 0);
    final hasFilters = activeFilterCount > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jobs'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: hasFilters,
              label: Text('$activeFilterCount'),
              child: const Icon(Icons.tune_rounded),
            ),
            tooltip: 'Filter Jobs',
            onPressed: () => _showFilter(context, state),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search jobs by title or technician…',
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(
                Theme.of(context).inputDecorationTheme.fillColor ??
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context).dividerTheme.color ?? const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              leading: const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.search_rounded, size: 20),
              ),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(jobsNotifierProvider.notifier).search('');
                    },
                  ),
              ],
              onChanged: (q) => ref.read(jobsNotifierProvider.notifier).search(q),
            ),
          ),
          Expanded(child: _buildList(state, hasFilters)),
        ],
      ),
    );
  }

  Widget _buildList(JobsState state, bool hasFilters) {
    if (state.isLoading) {
      return const AppLoadingView(message: 'Loading jobs...');
    }

    if (state.errorMessage != null && state.jobs.isEmpty) {
      return AppErrorView(
        message: state.errorMessage!,
        onRetry: () => ref.read(jobsNotifierProvider.notifier).refresh(),
      );
    }

    if (state.jobs.isEmpty) {
      final isSearching = _searchController.text.trim().isNotEmpty;
      return AppEmptyState(
        icon: isSearching ? Icons.search_off_rounded : Icons.assignment_outlined,
        title: isSearching ? 'No Matching Jobs' : 'No Jobs Found',
        message: isSearching || hasFilters
            ? 'No jobs match your current search or filter criteria. Try resetting them.'
            : 'There are currently no assigned jobs available.',
        actionLabel: hasFilters || isSearching ? 'Reset Filters' : null,
        onAction: () {
          _searchController.clear();
          ref.read(jobsNotifierProvider.notifier).search('');
          ref.read(jobsNotifierProvider.notifier).setFilter(const JobsFilter());
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(jobsNotifierProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 4, bottom: 24),
        itemCount: state.jobs.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.jobs.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            );
          }
          final job = state.jobs[index];
          return JobCard(
            job: job,
            onTap: () => context.push(AppRoutes.jobDetails.replaceAll(':id', job.id)),
          );
        },
      ),
    );
  }

  Future<void> _showFilter(BuildContext context, JobsState state) async {
    final result = await showModalBottomSheet<JobsFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FilterBottomSheet(current: state.filter),
    );
    if (result != null) {
      ref.read(jobsNotifierProvider.notifier).applyFilter(result);
    }
  }
}
