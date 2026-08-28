import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../core/constants/app_constants.dart';
import '../../features/jobs/domain/entities/job.dart';
import '../../features/jobs/domain/entities/job_status.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);
  }

  static Future<void> showJobAssigned(Job job) async {
    await _plugin.show(
      job.id.hashCode,
      'New job assigned',
      job.title,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'job_assigned',
          'Job Assigned',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  static Future<void> showSyncComplete(int count) async {
    if (count == 0) return;
    await _plugin.show(
      0,
      'Sync complete',
      '$count ${count == 1 ? 'operation' : 'operations'} synced successfully.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'sync_complete',
          'Sync Complete',
          importance: Importance.low,
          priority: Priority.low,
        ),
      ),
    );
  }

  // ── Deadline Reminders ─────────────────────────────────────────────────────

  static Future<void> scheduleDeadlineReminder(Job job) async {
    if (job.status == JobStatus.completed ||
        job.status == JobStatus.cancelled) {
      return;
    }

    final fireAt = job.scheduledAt.subtract(
      AppConstants.deadlineReminderLeadTime,
    );
    final now = DateTime.now();
    if (!fireAt.isAfter(now)) return; // already past — skip

    final tzFireAt = tz.TZDateTime.from(fireAt, tz.local);

    await _plugin.zonedSchedule(
      job.id.hashCode,
      'Upcoming job deadline',
      '${job.title} is scheduled in 1 hour.',
      tzFireAt,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'deadline_reminder',
          'Deadline Reminders',
          channelDescription: 'Fires 1 hour before each job\'s scheduled time.',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  /// Cancels the scheduled deadline reminder for [jobId]. Call this when a job
  /// transitions to [JobStatus.completed] or [JobStatus.cancelled].
  static Future<void> cancelDeadlineReminder(String jobId) async {
    await _plugin.cancel(jobId.hashCode);
  }
}
