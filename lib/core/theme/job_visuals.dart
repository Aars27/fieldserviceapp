import 'package:flutter/material.dart';

import '../../features/jobs/domain/entities/job_priority.dart';
import '../../features/jobs/domain/entities/job_status.dart';

class JobVisuals {
  JobVisuals._();

  static Color statusColor(BuildContext context, JobStatus status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (status) {
      JobStatus.pending => isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
      JobStatus.inProgress => isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
      JobStatus.completed => isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
      JobStatus.cancelled => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
    };
  }

  static Color statusBackgroundColor(BuildContext context, JobStatus status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (status) {
      JobStatus.pending =>
        isDark ? const Color(0xFF78350F).withValues(alpha: 0.35) : const Color(0xFFFEF3C7),
      JobStatus.inProgress =>
        isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.35) : const Color(0xFFDBEAFE),
      JobStatus.completed =>
        isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFD1FAE5),
      JobStatus.cancelled =>
        isDark ? const Color(0xFF334155).withValues(alpha: 0.35) : const Color(0xFFF1F5F9),
    };
  }

  static IconData statusIcon(JobStatus status) {
    return switch (status) {
      JobStatus.pending => Icons.schedule_rounded,
      JobStatus.inProgress => Icons.autorenew_rounded,
      JobStatus.completed => Icons.check_circle_outline_rounded,
      JobStatus.cancelled => Icons.cancel_outlined,
    };
  }

  static Color priorityColor(BuildContext context, JobPriority priority) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (priority) {
      JobPriority.low => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      JobPriority.normal => isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
      JobPriority.high => isDark ? const Color(0xFFFB923C) : const Color(0xFFEA580C),
      JobPriority.urgent => isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
    };
  }

  static Color priorityBackgroundColor(BuildContext context, JobPriority priority) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (priority) {
      JobPriority.low =>
        isDark ? const Color(0xFF334155).withValues(alpha: 0.3) : const Color(0xFFF1F5F9),
      JobPriority.normal =>
        isDark ? const Color(0xFF075985).withValues(alpha: 0.3) : const Color(0xFFE0F2FE),
      JobPriority.high =>
        isDark ? const Color(0xFF7C2D12).withValues(alpha: 0.3) : const Color(0xFFFFEDD5),
      JobPriority.urgent =>
        isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.3) : const Color(0xFFFEE2E2),
    };
  }

  static IconData priorityIcon(JobPriority priority) {
    return switch (priority) {
      JobPriority.low => Icons.south_rounded,
      JobPriority.normal => Icons.remove_rounded,
      JobPriority.high => Icons.north_rounded,
      JobPriority.urgent => Icons.priority_high_rounded,
    };
  }
}

class JobStatusBadge extends StatelessWidget {
  final JobStatus status;
  final bool showIcon;
  final double fontSize;

  const JobStatusBadge({
    super.key,
    required this.status,
    this.showIcon = true,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final fg = JobVisuals.statusColor(context, status);
    final bg = JobVisuals.statusBackgroundColor(context, status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.25), width: 0.75),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(JobVisuals.statusIcon(status), size: fontSize + 2, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            status.label,
            style: TextStyle(
              color: fg,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class JobPriorityBadge extends StatelessWidget {
  final JobPriority priority;
  final bool showIcon;
  final double fontSize;

  const JobPriorityBadge({
    super.key,
    required this.priority,
    this.showIcon = true,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final fg = JobVisuals.priorityColor(context, priority);
    final bg = JobVisuals.priorityBackgroundColor(context, priority);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.25), width: 0.75),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(JobVisuals.priorityIcon(priority), size: fontSize + 2, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            priority.label,
            style: TextStyle(
              color: fg,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
