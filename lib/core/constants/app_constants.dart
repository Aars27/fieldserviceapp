class AppConstants {
  AppConstants._();

  static const String appName = 'Field Service';

  // TODO: replace with real backend API URL once staging URL is available
  static const String baseUrl = 'https://mock-api.fieldservice.dev/api/v1';

  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 15000;

  static const int jobsPageSize = 15;
  static const Duration searchDebounce = Duration(milliseconds: 300);

  /// How far before a job's scheduled time to fire a deadline reminder.
  static const Duration deadlineReminderLeadTime = Duration(hours: 1);

  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String themeModeKey = 'theme_mode';

  static const String jobsBoxName = 'jobs_box';
  static const String pendingSyncBoxName = 'pending_sync_box';
  static const String seenJobIdsKey = 'seen_job_ids';
  static const String seenJobsInitializedKey = 'seen_jobs_initialized';
}
