import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repo;

  LoginUseCase(this._repo);

  Future<Result<AuthUser>> call(String email, String password) {
    if (email.trim().isEmpty || !email.contains('@')) {
      return Future.value(const Err(ValidationFailure('Enter a valid email address.')));
    }
    if (password.length < 6) {
      return Future.value(const Err(ValidationFailure('Password must be at least 6 characters.')));
    }
    return _repo.login(email.trim(), password);
  }
}
