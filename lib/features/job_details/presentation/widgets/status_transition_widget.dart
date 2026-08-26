import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Move to',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: validNext.map((next) {
              return FilledButton.tonal(
                onPressed: _updating ? null : () => _transition(next),
                child: _updating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(next.label),
              );
            }).toList(),
          ),
        ],
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
        SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
      );
    }
  }
}
