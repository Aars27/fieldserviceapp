import 'package:flutter/material.dart' hide StatusTransitionWidget;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/job_visuals.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../jobs/domain/entities/attachment.dart';
import '../../../jobs/domain/entities/job.dart';
import '../../../jobs/domain/entities/status_event.dart';
import '../../../notifications/presentation/providers/unseen_jobs_provider.dart';
import '../providers/job_detail_provider.dart';
import '../widgets/attachment_item.dart';
import '../widgets/status_transition_widget.dart';
import '../widgets/timeline_tile.dart';

class JobDetailsScreen extends ConsumerWidget {
  final String jobId;

  const JobDetailsScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Automatically mark this job as seen when viewed
    Future.microtask(() {
      ref.read(seenJobsNotifierProvider.notifier).markSeen(jobId);
    });

    final asyncJob = ref.watch(jobDetailProvider(jobId));

    return asyncJob.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Job Details')),
        body: const AppLoadingView(message: 'Loading job details...'),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Job Details')),
        body: AppErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(jobDetailProvider(jobId)),
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardTheme.color ??
        (isDark ? const Color(0xFF1E293B) : Colors.white);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (job.isOverdue) ...[
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.3) : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF991B1B) : const Color(0xFFFECACA),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This job is overdue for completion.',
                    style: TextStyle(
                      color: isDark ? const Color(0xFFFEE2E2) : const Color(0xFF991B1B),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        Material(
          color: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  icon: Icons.flag_outlined,
                  label: 'Status',
                  child: JobStatusBadge(status: job.status),
                ),
                _InfoRow(
                  icon: Icons.bolt_rounded,
                  label: 'Priority',
                  child: JobPriorityBadge(priority: job.priority),
                ),
                _InfoRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Assigned To',
                  child: Text(
                    job.assignedTo,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                _InfoRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Scheduled',
                  child: Text(
                    DateFormat('EEEE, MMM d, y · h:mm a').format(job.scheduledAt),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                if (job.latitude != null && job.longitude != null) ...[ 
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Coordinates',
                    child: Text(
                      '${job.latitude!.toStringAsFixed(4)}, ${job.longitude!.toStringAsFixed(4)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (job.description.isNotEmpty) ...[
          const SizedBox(height: 16),
          Material(
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notes_rounded, size: 18, color: cs.outline),
                      const SizedBox(width: 8),
                      Text(
                        'Job Description',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    job.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color: cs.onSurface,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        _MapCard(job: job, cardBg: cardBg, borderColor: borderColor),
      ],
    );
  }
}

class _MapCard extends StatelessWidget {
  final Job job;
  final Color cardBg;
  final Color borderColor;

  const _MapCard({required this.job, required this.cardBg, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasLocation = job.latitude != null && job.longitude != null;

    return Material(
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Icon(Icons.map_outlined, size: 18, color: cs.outline),
                const SizedBox(width: 8),
                Text(
                  'Location',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          if (!hasLocation)
            Container(
              height: 120,
              alignment: Alignment.center,
              color: cs.surfaceContainerHighest,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_off_rounded, size: 32, color: cs.outline),
                  const SizedBox(height: 8),
                  Text(
                    'Location not available',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.outline,
                        ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 220,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(job.latitude!, job.longitude!),
                  initialZoom: 14,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.fieldserviceapp',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(job.latitude!, job.longitude!),
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.location_pin,
                          size: 40,
                          color: cs.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: cs.outline),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.outline,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(child: child),
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
      return const AppEmptyState(
        icon: Icons.history_rounded,
        title: 'No Timeline Events',
        message: 'No status changes or history recorded for this job yet.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
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
              ? const AppEmptyState(
                  icon: Icons.attach_file_rounded,
                  title: 'No Attachments',
                  message: 'Attach photos or documents related to this job.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: attachments.length,
                  itemBuilder: (context, i) => AttachmentItem(
                    attachment: attachments[i],
                    jobId: jobId,
                  ),
                ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerTheme.color ?? const Color(0xFFE2E8F0),
              ),
            ),
          ),
          child: AddAttachmentButton(jobId: jobId),
        ),
      ],
    );
  }
}
