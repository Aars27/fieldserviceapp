import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/job.dart';
import '../../domain/entities/job_priority.dart';
import '../../domain/entities/job_status.dart';

class JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;

  const JobCard({super.key, required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _PriorityDot(priority: job.priority),
                  const SizedBox(width: 6),
                  _StatusChip(status: job.status),
                ],
              ),
              if (job.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  job.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: cs.outline),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d, h:mm a').format(job.scheduledAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: job.isOverdue ? cs.error : cs.outline,
                        ),
                  ),
                  if (job.isOverdue) ...[
                    const SizedBox(width: 4),
                    Text(
                      'Overdue',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.error,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityDot extends StatelessWidget {
  final JobPriority priority;
  const _PriorityDot({required this.priority});

  Color _color(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return switch (priority) {
      JobPriority.low => cs.outline,
      JobPriority.normal => cs.primary,
      JobPriority.high => Colors.orange,
      JobPriority.urgent => cs.error,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: priority.label,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: _color(context), shape: BoxShape.circle),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final JobStatus status;
  const _StatusChip({required this.status});

  Color _bg(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return switch (status) {
      JobStatus.pending => cs.secondaryContainer,
      JobStatus.inProgress => cs.tertiaryContainer,
      JobStatus.completed => cs.primaryContainer,
      JobStatus.cancelled => cs.errorContainer,
    };
  }

  Color _fg(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return switch (status) {
      JobStatus.pending => cs.onSecondaryContainer,
      JobStatus.inProgress => cs.onTertiaryContainer,
      JobStatus.completed => cs.onPrimaryContainer,
      JobStatus.cancelled => cs.onErrorContainer,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _bg(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: _fg(context)),
      ),
    );
  }
}
