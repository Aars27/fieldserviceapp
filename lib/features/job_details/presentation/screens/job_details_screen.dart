import 'package:flutter/material.dart' hide StatusTransitionWidget;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../jobs/domain/entities/attachment.dart';
import '../../../jobs/domain/entities/job.dart';
import '../../../jobs/domain/entities/status_event.dart';
import '../providers/job_detail_provider.dart';
import '../widgets/attachment_item.dart';
import '../widgets/status_transition_widget.dart';
import '../widgets/timeline_tile.dart';

class JobDetailsScreen extends ConsumerWidget {
  final String jobId;

  const JobDetailsScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncJob = ref.watch(jobDetailProvider(jobId));

    return asyncJob.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('$e')),
      ),
      data: (job) => DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text(job.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'Timeline'),
                Tab(text: 'Attachments'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _OverviewTab(job: job),
              _TimelineTab(events: job.timeline),
              _AttachmentsTab(jobId: job.id, attachments: job.attachments),
            ],
          ),
          bottomNavigationBar: StatusTransitionWidget(
            jobId: job.id,
            currentStatus: job.status,
          ),
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Job job;
  const _OverviewTab({required this.job});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoRow(label: 'Status', value: job.status.label),
        _InfoRow(label: 'Priority', value: job.priority.label),
        _InfoRow(label: 'Assigned to', value: job.assignedTo),
        _InfoRow(
          label: 'Scheduled',
          value: DateFormat('MMM d, y · h:mm a').format(job.scheduledAt),
        ),
        if (job.description.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Description', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(job.description, style: Theme.of(context).textTheme.bodyMedium),
        ],
        if (job.isOverdue) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: cs.error),
                const SizedBox(width: 8),
                Text('This job is overdue.', style: TextStyle(color: cs.error)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _TimelineTab extends StatelessWidget {
  final List<StatusEvent> events;
  const _TimelineTab({required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Center(child: Text('No status history yet.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, i) => TimelineTile(
        event: events[i],
        isLast: i == events.length - 1,
      ),
    );
  }
}

class _AttachmentsTab extends StatelessWidget {
  final String jobId;
  final List<Attachment> attachments;
  const _AttachmentsTab({required this.jobId, required this.attachments});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: attachments.isEmpty
              ? const Center(child: Text('No attachments yet.'))
              : ListView.builder(
                  itemCount: attachments.length,
                  itemBuilder: (context, i) => AttachmentItem(
                    attachment: attachments[i],
                    jobId: jobId,
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: AddAttachmentButton(jobId: jobId),
        ),
      ],
    );
  }
}
