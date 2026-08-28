import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/job_visuals.dart';
import '../../domain/entities/job.dart';

class JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;

  const JobCard({super.key, required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardTheme.color ??
        (isDark ? const Color(0xFF1E293B) : Colors.white);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: job.isOverdue
                ? (isDark ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5))
                : borderColor,
            width: job.isOverdue ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        job.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    JobPriorityBadge(priority: job.priority, fontSize: 10),
                  ],
                ),
                if (job.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    job.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.35,
                        ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    JobStatusBadge(status: job.status, fontSize: 10),
                    const Spacer(),
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: job.isOverdue ? cs.error : cs.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d, h:mm a').format(job.scheduledAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: job.isOverdue ? cs.error : cs.outline,
                            fontWeight: job.isOverdue ? FontWeight.w600 : FontWeight.w500,
                          ),
                    ),
                    if (job.isOverdue) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'OVERDUE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
