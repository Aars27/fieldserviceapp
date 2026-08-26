import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/jobs/domain/entities/job.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    // TODO: add iOS DarwinInitializationSettings once entitlements are configured
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
}
