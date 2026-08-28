import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/job_visuals.dart';
import '../../../sync/presentation/providers/sync_provider.dart';
import '../../domain/entities/job.dart';

class JobCard extends ConsumerWidget {
  final Job job;
  final bool isNew;
  final VoidCallback onTap;

  const JobCard({
    super.key,
    required this.job,
    this.isNew = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardTheme.color ??
        (isDark ? const Color(0xFF1E293B) : Colors.white);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final isPendingSync = ref.watch(isJobPendingSyncProvider(job.id));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isNew
                ? cs.primary
                : job.isOverdue
                    ? (isDark ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5))
                    : borderColor,
            width: isNew ? 1.5 : (job.isOverdue ? 1.5 : 1),
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
                    if (isNew) ...[
                      Container(
                        margin: const EdgeInsets.only(right: 8, top: 1),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
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
                    if (isPendingSync) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF78350F).withValues(alpha: 0.6)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
                                : const Color(0xFFFBBF24),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 10,
                              color: isDark
                                  ? const Color(0xFFFCD34D)
                                  : const Color(0xFFB45309),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'PENDING SYNC',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? const Color(0xFFFCD34D)
                                    : const Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
