import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/unseen_jobs_provider.dart';
import 'notifications_bottom_sheet.dart';

/// App bar bell icon button with unseen jobs count badge.
/// The badge is hidden entirely when there are 0 unseen jobs.
class NotificationsBellButton extends ConsumerWidget {
  const NotificationsBellButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unseenCount = ref.watch(unseenJobsCountProvider);

    return IconButton(
      tooltip: 'New Job Notifications',
      icon: Badge.count(
        count: unseenCount,
        isLabelVisible: unseenCount > 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        textColor: Colors.white,
        child: const Icon(Icons.notifications_outlined),
      ),
      onPressed: () => _openNotificationsSheet(context),
    );
  }

  void _openNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationsBottomSheet(),
    );
  }
}
