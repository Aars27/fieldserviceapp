import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../domain/repositories/job_repository.dart';
import '../providers/jobs_provider.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/job_card.dart';

class JobsListScreen extends ConsumerStatefulWidget {
  const JobsListScreen({super.key});

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
    Future.microtask(() => ref.read(jobsNotifierProvider.notifier).loadInitial());
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
    final hasFilters = state.filter.statuses.isNotEmpty ||
        state.filter.priorities.isNotEmpty ||
        state.filter.from != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jobs'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: hasFilters,
              child: const Icon(Icons.tune),
            ),
            tooltip: 'Filter',
            onPressed: () => _showFilter(context, state),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search jobs…',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(jobsNotifierProvider.notifier).search('');
                    },
                  ),
              ],
              onChanged: (q) => ref.read(jobsNotifierProvider.notifier).search(q),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildList(state)),
        ],
      ),
    );
  }

  Widget _buildList(JobsState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.errorMessage!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => ref.read(jobsNotifierProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.jobs.isEmpty) {
      return const Center(child: Text('No jobs found.'));
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(jobsNotifierProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: state.jobs.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.jobs.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
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
      builder: (_) => FilterBottomSheet(current: state.filter),
    );
    if (result != null) {
      ref.read(jobsNotifierProvider.notifier).applyFilter(
            statuses: result.statuses,
            priorities: result.priorities,
            from: result.from,
            to: result.to,
          );
    }
  }
}
