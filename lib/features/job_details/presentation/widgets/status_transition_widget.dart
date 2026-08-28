import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/job_visuals.dart';
import '../../../jobs/domain/entities/job_status.dart';
import '../providers/job_detail_provider.dart';

class StatusTransitionWidget extends ConsumerStatefulWidget {
  final String jobId;
  final JobStatus currentStatus;

  const StatusTransitionWidget({
    super.key,
    required this.jobId,
    required this.currentStatus,
  });

  @override
  ConsumerState<StatusTransitionWidget> createState() => _StatusTransitionWidgetState();
}

class _StatusTransitionWidgetState extends ConsumerState<StatusTransitionWidget> {
  bool _updating = false;

  @override
  Widget build(BuildContext context) {
    final validNext = JobStatus.validTransitions[widget.currentStatus] ?? {};
    if (validNext.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerTheme.color ?? const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'UPDATE STATUS',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: validNext.map((next) {
                final color = JobVisuals.statusColor(context, next);
                final icon = JobVisuals.statusIcon(next);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _updating ? null : () => _transition(next),
                      icon: _updating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(icon, size: 18),
                      label: Text(
                        next.label,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _transition(JobStatus next) async {
    setState(() => _updating = true);
    final error = await ref
        .read(jobDetailProvider(widget.jobId).notifier)
        .updateStatus(next);
    if (!mounted) return;
    setState(() => _updating = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}
