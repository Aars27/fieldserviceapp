import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/job_visuals.dart';
import '../../../jobs/domain/entities/status_event.dart';

class TimelineTile extends StatelessWidget {
  final StatusEvent event;
  final bool isLast;

  const TimelineTile({super.key, required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = JobVisuals.statusColor(context, event.status);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: cs.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      JobStatusBadge(status: event.status, fontSize: 11),
                      const Spacer(),
                      Text(
                        DateFormat('MMM d, y · h:mm a').format(event.createdAt),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.outline,
                            ),
                      ),
                    ],
                  ),
                  if (event.note?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        event.note!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurface,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
