import 'package:dio/dio.dart';

import '../storage/secure_storage_service.dart';

/// Attaches the access token to every outgoing request and, on a 401,
/// tries a single refresh-and-retry before giving up. Without the
/// `_isRefreshing` guard, concurrent 401s (e.g. jobs list + dashboard
/// firing at once) would each kick off their own refresh call.
class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final SecureStorageService _secureStorage;

  bool _isRefreshing = false;

  AuthInterceptor(this._dio, this._secureStorage);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _secureStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final isRetry = err.requestOptions.extra['retried'] == true;

    if (!isUnauthorized || isRetry || _isRefreshing) {
      return handler.next(err);
    }

    _isRefreshing = true;
    try {
      final refreshed = await _refreshToken();
      _isRefreshing = false;

      if (!refreshed) {
        await _secureStorage.clearTokens();
        return handler.next(err);
      }

      final retryOptions = err.requestOptions;
      retryOptions.extra['retried'] = true;
      final newToken = await _secureStorage.getAccessToken();
      retryOptions.headers['Authorization'] = 'Bearer $newToken';

      final response = await _dio.fetch(retryOptions);
      return handler.resolve(response);
    } catch (_) {
      _isRefreshing = false;
      await _secureStorage.clearTokens();
      return handler.next(err);
    }
  }

  Future<bool> _refreshToken() async {
    final refreshToken = await _secureStorage.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(extra: {'retried': true}),
      );

      final newAccessToken = response.data['access_token'] as String?;
      final newRefreshToken = response.data['refresh_token'] as String?;
      if (newAccessToken == null) return false;

      await _secureStorage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken ?? refreshToken,
      );
      return true;
    } on DioException {
      return false;
    }
  }
}
