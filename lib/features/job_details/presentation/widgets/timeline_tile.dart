import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../jobs/domain/entities/status_event.dart';

class TimelineTile extends StatelessWidget {
  final StatusEvent event;
  final bool isLast;

  const TimelineTile({super.key, required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: cs.outlineVariant),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.status.label,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (event.note?.isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(event.note!, style: Theme.of(context).textTheme.bodySmall),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM d, y · h:mm a').format(event.createdAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.outline,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
