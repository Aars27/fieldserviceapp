import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/auth_user_model.dart';

class AuthRemoteDatasource {
  final Dio _dio;

  AuthRemoteDatasource(this._dio);

  Future<({AuthUserModel user, String accessToken, String refreshToken})> login(
    String email,
    String password,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
        // Skip the auth interceptor retry loop for this specific call
        options: Options(extra: {'retried': true}),
      );

      final data = response.data as Map<String, dynamic>;
      return (
        user: AuthUserModel.fromJson(data['user'] as Map<String, dynamic>),
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw AuthException('Invalid email or password.');
      }
      throw ServerException(
        e.response?.data?['message'] as String? ?? 'Login failed.',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
