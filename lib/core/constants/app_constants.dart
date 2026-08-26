class AppConstants {
  AppConstants._();

  static const String appName = 'Field Service';

  // TODO: swap to real backend once staging URL is available
  static const String baseUrl = 'https://mock-api.fieldservice.dev/api/v1';

  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 15000;

  static const int jobsPageSize = 15;
  static const Duration searchDebounce = Duration(milliseconds: 300);

  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String themeModeKey = 'theme_mode';

  static const String jobsBoxName = 'jobs_box';
  static const String pendingSyncBoxName = 'pending_sync_box';
}
