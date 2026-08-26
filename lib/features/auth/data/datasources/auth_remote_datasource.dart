import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/auth_user_model.dart';

/// Simulates the login endpoint locally since no real backend is provided
/// for this assessment.
class AuthRemoteDatasource {
  const AuthRemoteDatasource([Dio? _]);

  Future<({AuthUserModel user, String accessToken, String refreshToken})> login(
    String email,
    String password,
  ) async {
    // Simulate network latency
    await Future.delayed(const Duration(milliseconds: 700));

    final normalizedEmail = email.trim();
    if (normalizedEmail == 'fail@test.com' ||
        !normalizedEmail.contains('@') ||
        password.length < 6) {
      throw AuthException('Invalid email or password.');
    }

    final accessToken = 'mock_access_${DateTime.now().millisecondsSinceEpoch}';
    final refreshToken =
        'mock_refresh_${DateTime.now().millisecondsSinceEpoch}';

    final user = AuthUserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: normalizedEmail.split('@').first,
      email: normalizedEmail,
      role: 'technician',
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    return (user: user, accessToken: accessToken, refreshToken: refreshToken);
  }
}
