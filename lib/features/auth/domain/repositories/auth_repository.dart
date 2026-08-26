import '../../../../core/errors/result.dart';
import '../entities/auth_user.dart';

abstract class AuthRepository {
  Future<Result<AuthUser>> login(String email, String password);
  Future<void> logout();
  Future<bool> get hasSession;
}
